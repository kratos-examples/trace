# Changes

Code differences compared to source project.

## cmd/demo2kratos/main.go (+2 -0)

```diff
@@ -14,6 +14,7 @@
 	"github.com/go-kratos/kratos/v3/transport/http"
 	"github.com/yylego/done"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/conf"
+	"github.com/yylego/kratos-trace/tracekratos"
 	"github.com/yylego/must"
 	"github.com/yylego/rese"
 
@@ -56,6 +57,7 @@
 			Level:     slog.LevelInfo,
 		}),
 		log.WithExtractor(tracing.TraceAttrs),
+		log.WithExtractor(tracekratos.LogTraceID("request-trace")), // 我们自己的 trace ID，与官方 trace 属性并行
 	).With(
 		slog.String("service.id", done.VCE(os.Hostname()).Omit()),
 		slog.String("service.name", Name),
```

## cmd/demo2kratos/wire_gen.go (+5 -2)

```diff
@@ -28,16 +28,19 @@
 	if err != nil {
 		return nil, nil, err
 	}
-	articleUsecase, err := biz.NewArticleUsecase(dataData, logger)
+	demo1HttpClient, cleanup2 := data.NewDemo1HttpClient(logger)
+	articleUsecase, err := biz.NewArticleUsecase(dataData, demo1HttpClient, logger)
 	if err != nil {
+		cleanup2()
 		cleanup()
 		return nil, nil, err
 	}
-	articleService := service.NewArticleService(articleUsecase)
+	articleService := service.NewArticleService(articleUsecase, logger)
 	grpcServer := server.NewGRPCServer(confServer, articleService, logger)
 	httpServer := server.NewHTTPServer(confServer, articleService, logger)
 	app := newApp(logger, grpcServer, httpServer)
 	return app, func() {
+		cleanup2()
 		cleanup()
 	}, nil
 }
```

## internal/biz/article.go (+17 -5)

```diff
@@ -6,6 +6,7 @@
 	"log/slog"
 
 	"github.com/yylego/kratos-ebz/ebzkratos"
+	demo1student "github.com/yylego/kratos-examples/demo1kratos/api/student"
 	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/data"
 	"github.com/yylego/must"
@@ -29,18 +30,19 @@
 func (Article) TableName() string { return "articles" }
 
 type ArticleUsecase struct {
-	data *data.Data
-	slog *slog.Logger
+	data            *data.Data
+	demo1HttpClient *data.Demo1HttpClient
+	slog            *slog.Logger
 }
 
-func NewArticleUsecase(data *data.Data, logger *slog.Logger) (*ArticleUsecase, error) {
+func NewArticleUsecase(data *data.Data, demo1HttpClient *data.Demo1HttpClient, logger *slog.Logger) (*ArticleUsecase, error) {
 	// Migrate the owned table plus the mirrored students table (needed in the
 	// existence check); both services share one database
 	// 建好本服务拥有的 articles 表，外加镜像的 students 表（供存在性校验用）
 	if err := data.DB().AutoMigrate(&Article{}, &Student{}); err != nil {
 		return nil, err
 	}
-	return &ArticleUsecase{data: data, slog: logger}, nil
+	return &ArticleUsecase{data: data, demo1HttpClient: demo1HttpClient, slog: logger}, nil
 }
 
 func (uc *ArticleUsecase) CreateArticle(ctx context.Context, a *Article) (*Article, *ebzkratos.Ebz) {
@@ -55,7 +57,17 @@
 	// （它持 FOR UPDATE）在本事务提交前删除该学生，从而绝不会创建出指向
 	// "正在被删除的学生"的文章
 	res := &Article{Title: a.Title, Content: a.Content, StudentID: a.StudentID}
-	err := uc.data.DB().WithContext(ctx).Transaction(func(db *gorm.DB) error {
+
+	// 跨服务调用 demo1kratos：trace ID 会通过 HTTP header 传播到对端，演示跨服务链路追踪
+	resp, err := uc.demo1HttpClient.GetStudentClient().CreateStudent(ctx, &demo1student.CreateStudentRequest{
+		Name: a.Title,
+	})
+	if err != nil {
+		return nil, ebzkratos.New(pb.ErrorArticleCreateFailure("call demo1 over http: %v", err))
+	}
+	res.Content = res.Content + " [http-resp:" + resp.GetStudent().GetName() + "]"
+
+	err = uc.data.DB().WithContext(ctx).Transaction(func(db *gorm.DB) error {
 		var student Student
 		if err := db.Clauses(clause.Locking{Strength: clause.LockingStrengthShare}).First(&student, a.StudentID).Error; err != nil {
 			return err
```

## internal/data/data.go (+1 -1)

```diff
@@ -11,7 +11,7 @@
 	"gorm.io/gorm"
 )
 
-var ProviderSet = wire.NewSet(NewData)
+var ProviderSet = wire.NewSet(NewData, NewDemo1HttpClient)
 
 type Data struct {
 	db *gorm.DB
```

## internal/data/demo1_http_client.go (+48 -0)

```diff
@@ -0,0 +1,48 @@
+package data
+
+import (
+	"context"
+	"log/slog"
+
+	"github.com/go-kratos/kratos/v3/middleware"
+	"github.com/go-kratos/kratos/v3/transport/http"
+	demo1student "github.com/yylego/kratos-examples/demo1kratos/api/student"
+	"github.com/yylego/kratos-trace/tracekratos"
+	"github.com/yylego/must"
+	"github.com/yylego/rese"
+)
+
+type Demo1HttpClient struct {
+	client        *http.Client
+	studentClient demo1student.StudentServiceHTTPClient
+}
+
+func NewDemo1HttpClient(logger *slog.Logger) (*Demo1HttpClient, func()) {
+	// 直接连接 demo1kratos 的 HTTP 端口，trace ID 会通过 HTTP header 跨服务传播
+	client := rese.P1(http.NewClient(
+		context.Background(),
+		http.WithEndpoint("http://127.0.0.1:8001"),
+		http.WithMiddleware(
+			// 把当前请求的 trace ID 写进出站 HTTP header，让下游 demo1 收到同一个 trace ID
+			tracekratos.NewClientMiddleware(tracekratos.NewConfig("TRACE_ID")),
+			func(handler middleware.Handler) middleware.Handler {
+				logger.Info("handle http request in middleware")
+				return func(ctx context.Context, req any) (any, error) {
+					return handler(ctx, req)
+				}
+			},
+		),
+	))
+	studentClient := demo1student.NewStudentServiceHTTPClient(client)
+	cleanup := func() {
+		must.Done(client.Close())
+	}
+	return &Demo1HttpClient{
+		client:        client,
+		studentClient: studentClient,
+	}, cleanup
+}
+
+func (c *Demo1HttpClient) GetStudentClient() demo1student.StudentServiceHTTPClient {
+	return c.studentClient
+}
```

## internal/server/http.go (+26 -0)

```diff
@@ -1,19 +1,29 @@
 package server
 
 import (
+	"context"
 	"log/slog"
+	"strconv"
+	"time"
 
+	"github.com/go-kratos/kratos/v3/log"
+	"github.com/go-kratos/kratos/v3/middleware"
+	"github.com/go-kratos/kratos/v3/middleware/logging"
 	"github.com/go-kratos/kratos/v3/middleware/recovery"
 	"github.com/go-kratos/kratos/v3/transport/http"
+	"github.com/google/uuid"
 	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/conf"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/service"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 func NewHTTPServer(c *conf.Server, article *service.ArticleService, logger *slog.Logger) *http.Server {
 	var opts = []http.ServerOption{
 		http.Middleware(
 			recovery.Recovery(),
+			NewTraceMiddleware(logger), // 在请求逻辑执行前打印日志，显示请求参数和追踪信息
+			logging.Server(logger),     // 在请求逻辑执行后打印日志，显示执行结果的错误码和状态码
 		),
 	}
 	if c.Http.Network != "" {
@@ -28,4 +38,20 @@
 	srv := http.NewServer(opts...)
 	pb.RegisterArticleServiceHTTPServer(srv, article)
 	return srv
+}
+
+func NewTraceMiddleware(logger *slog.Logger) middleware.Middleware {
+	// Demo tracekratos features using function options
+	// 演示 tracekratos 的功能选项
+	config := tracekratos.NewConfig("TRACE_ID",
+		tracekratos.WithLogLevel(log.LevelDebug),
+		tracekratos.WithLogReply(true),
+		tracekratos.WithNewTraceID(func(ctx context.Context) string {
+			return "TRACE-ID-" + strconv.FormatInt(time.Now().UnixNano(), 10) + "-" + uuid.New().String() + "-AAA"
+		}),
+		tracekratos.WithFormatArgs(func(req any) string {
+			return tracekratos.ExtractArgs(req)
+		}),
+	)
+	return tracekratos.NewTraceMiddleware(config, logger)
 }
```

## internal/service/article.go (+14 -3)

```diff
@@ -2,22 +2,33 @@
 
 import (
 	"context"
+	"log/slog"
 
 	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/biz"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 type ArticleService struct {
 	pb.UnimplementedArticleServiceServer
 
-	uc *biz.ArticleUsecase
+	uc  *biz.ArticleUsecase
+	log *slog.Logger
 }
 
-func NewArticleService(uc *biz.ArticleUsecase) *ArticleService {
-	return &ArticleService{uc: uc}
+func NewArticleService(uc *biz.ArticleUsecase, logger *slog.Logger) *ArticleService {
+	return &ArticleService{
+		uc:  uc,
+		log: logger,
+	}
 }
 
 func (s *ArticleService) CreateArticle(ctx context.Context, req *pb.CreateArticleRequest) (*pb.CreateArticleReply, error) {
+	// Demo GetTraceID feature from tracekratos
+	// 演示 tracekratos 的 GetTraceID 功能
+	traceID := tracekratos.GetTraceID(ctx)
+	s.log.InfoContext(ctx, "Processing request with trace ID", "trace_id", traceID)
+
 	if req.Title == "" {
 		return nil, pb.ErrorBadParam("TITLE IS REQUIRED")
 	}
```

