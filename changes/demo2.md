# Changes

Code differences compared to source project.

## cmd/demo2kratos/wire_gen.go (+1 -1)

```diff
@@ -24,7 +24,7 @@
 		return nil, nil, err
 	}
 	articleUsecase := biz.NewArticleUsecase(dataData, logger)
-	articleService := service.NewArticleService(articleUsecase)
+	articleService := service.NewArticleService(articleUsecase, logger)
 	grpcServer := server.NewGRPCServer(confServer, articleService, logger)
 	httpServer := server.NewHTTPServer(confServer, articleService, logger)
 	app := newApp(logger, grpcServer, httpServer)
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

