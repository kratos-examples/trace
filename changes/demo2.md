# Changes

Code differences compared to source project.

## cmd/demo2kratos/wire_gen.go (+4 -2)

```diff
@@ -23,12 +23,14 @@
 	if err != nil {
 		return nil, nil, err
 	}
-	articleUsecase := biz.NewArticleUsecase(dataData, logger)
-	articleService := service.NewArticleService(articleUsecase)
+	demo1HttpClient, cleanup2 := data.NewDemo1HttpClient(logger)
+	articleUsecase := biz.NewArticleUsecase(dataData, demo1HttpClient, logger)
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

## internal/biz/article.go (+14 -4)

```diff
@@ -6,6 +6,7 @@
 	"github.com/brianvoe/gofakeit/v7"
 	"github.com/go-kratos/kratos/v2/log"
 	"github.com/yylego/kratos-ebz/ebzkratos"
+	demo1student "github.com/yylego/kratos-examples/demo1kratos/api/student"
 	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/data"
 )
@@ -18,12 +19,13 @@
 }
 
 type ArticleUsecase struct {
-	data *data.Data
-	log  *log.Helper
+	data            *data.Data
+	demo1HttpClient *data.Demo1HttpClient
+	log             *log.Helper
 }
 
-func NewArticleUsecase(data *data.Data, logger log.Logger) *ArticleUsecase {
-	return &ArticleUsecase{data: data, log: log.NewHelper(logger)}
+func NewArticleUsecase(data *data.Data, demo1HttpClient *data.Demo1HttpClient, logger log.Logger) *ArticleUsecase {
+	return &ArticleUsecase{data: data, demo1HttpClient: demo1HttpClient, log: log.NewHelper(logger)}
 }
 
 func (uc *ArticleUsecase) CreateArticle(ctx context.Context, a *Article) (*Article, *ebzkratos.Ebz) {
@@ -31,6 +33,14 @@
 	if err := gofakeit.Struct(&res); err != nil {
 		return nil, ebzkratos.New(pb.ErrorArticleCreateFailure("fake: %v", err))
 	}
+	// 跨服务调用 demo1kratos，trace ID 会通过 HTTP header 传播
+	resp, err := uc.demo1HttpClient.GetStudentClient().CreateStudent(ctx, &demo1student.CreateStudentRequest{
+		Name: res.Title,
+	})
+	if err != nil {
+		return nil, ebzkratos.New(pb.ErrorServerError("http: %v", err))
+	}
+	res.Title = "message:[http-resp:" + resp.GetStudent().GetName() + "]"
 	return &res, nil
 }
 
```

## internal/data/data.go (+1 -1)

```diff
@@ -10,7 +10,7 @@
 	"gorm.io/gorm"
 )
 
-var ProviderSet = wire.NewSet(NewData)
+var ProviderSet = wire.NewSet(NewData, NewDemo1HttpClient)
 
 type Data struct {
 	db *gorm.DB
```

## internal/data/demo1_http_client.go (+45 -0)

```diff
@@ -0,0 +1,45 @@
+package data
+
+import (
+	"context"
+
+	"github.com/go-kratos/kratos/v2/log"
+	"github.com/go-kratos/kratos/v2/middleware"
+	"github.com/go-kratos/kratos/v2/transport/http"
+	demo1student "github.com/yylego/kratos-examples/demo1kratos/api/student"
+	"github.com/yylego/must"
+	"github.com/yylego/rese"
+)
+
+type Demo1HttpClient struct {
+	client        *http.Client
+	studentClient demo1student.StudentServiceHTTPClient
+}
+
+func NewDemo1HttpClient(logger log.Logger) (*Demo1HttpClient, func()) {
+	LOG := log.NewHelper(logger)
+
+	// 直接连接 demo1kratos 的 HTTP 端口，trace ID 会通过 HTTP header 跨服务传播
+	client := rese.P1(http.NewClient(
+		context.Background(),
+		http.WithEndpoint("http://127.0.0.1:8000"),
+		http.WithMiddleware(func(handler middleware.Handler) middleware.Handler {
+			LOG.Infof("handle http request in middleware")
+			return func(ctx context.Context, req any) (any, error) {
+				return handler(ctx, req)
+			}
+		}),
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
@@ -1,18 +1,28 @@
 package server
 
 import (
+	"context"
+	"strconv"
+	"time"
+
 	"github.com/go-kratos/kratos/v2/log"
+	"github.com/go-kratos/kratos/v2/middleware"
+	"github.com/go-kratos/kratos/v2/middleware/logging"
 	"github.com/go-kratos/kratos/v2/middleware/recovery"
 	"github.com/go-kratos/kratos/v2/transport/http"
+	"github.com/google/uuid"
 	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/conf"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/service"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 func NewHTTPServer(c *conf.Server, article *service.ArticleService, logger log.Logger) *http.Server {
 	var opts = []http.ServerOption{
 		http.Middleware(
 			recovery.Recovery(),
+			NewTraceMiddleware(logger), //在请求逻辑执行前打印日志，显示请求参数和追踪信息
+			logging.Server(logger),     //在请求逻辑执行后打印日志，显示执行结果的错误码和状态码
 		),
 	}
 	if c.Http.Network != "" {
@@ -27,4 +37,20 @@
 	srv := http.NewServer(opts...)
 	pb.RegisterArticleServiceHTTPServer(srv, article)
 	return srv
+}
+
+func NewTraceMiddleware(logger log.Logger) middleware.Middleware {
+	// Demo tracekratos features using function options
+	// 演示 tracekratos 的功能选项
+	config := tracekratos.NewConfig("TRACE_ID",
+		tracekratos.WithLogLevel(log.LevelInfo),
+		tracekratos.WithLogReply(true),
+		tracekratos.WithNewTraceID(func(ctx context.Context) string {
+			return "TRACE-ID-" + strconv.FormatInt(time.Now().UnixNano(), 10) + "-" + uuid.New().String() + "-BBB"
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
@@ -3,21 +3,32 @@
 import (
 	"context"
 
+	"github.com/go-kratos/kratos/v2/log"
 	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
 	"github.com/yylego/kratos-examples/demo2kratos/internal/biz"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 type ArticleService struct {
 	pb.UnimplementedArticleServiceServer
 
-	uc *biz.ArticleUsecase
+	uc  *biz.ArticleUsecase
+	log *log.Helper
 }
 
-func NewArticleService(uc *biz.ArticleUsecase) *ArticleService {
-	return &ArticleService{uc: uc}
+func NewArticleService(uc *biz.ArticleUsecase, logger log.Logger) *ArticleService {
+	return &ArticleService{
+		uc:  uc,
+		log: log.NewHelper(logger),
+	}
 }
 
 func (s *ArticleService) CreateArticle(ctx context.Context, req *pb.CreateArticleRequest) (*pb.CreateArticleReply, error) {
+	// Demo GetTraceID feature from tracekratos
+	// 演示 tracekratos 的 GetTraceID 功能
+	traceID := tracekratos.GetTraceID(ctx)
+	s.log.WithContext(ctx).Infof("Processing request with trace ID: %s", traceID)
+
 	v, ebz := s.uc.CreateArticle(ctx, nil)
 	if ebz != nil {
 		return nil, ebz.Erk
```

