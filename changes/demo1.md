# Changes

Code differences compared to source project.

## cmd/demo1kratos/main.go (+2 -0)

```diff
@@ -14,6 +14,7 @@
 	"github.com/go-kratos/kratos/v3/transport/http"
 	"github.com/yylego/done"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/conf"
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

## cmd/demo1kratos/wire_gen.go (+1 -1)

```diff
@@ -33,7 +33,7 @@
 		cleanup()
 		return nil, nil, err
 	}
-	studentService := service.NewStudentService(studentUsecase)
+	studentService := service.NewStudentService(studentUsecase, logger)
 	grpcServer := server.NewGRPCServer(confServer, studentService, logger)
 	httpServer := server.NewHTTPServer(confServer, studentService, logger)
 	app := newApp(logger, grpcServer, httpServer)
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
 	pb "github.com/yylego/kratos-examples/demo1kratos/api/student"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/conf"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/service"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 func NewHTTPServer(c *conf.Server, student *service.StudentService, logger *slog.Logger) *http.Server {
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
 	pb.RegisterStudentServiceHTTPServer(srv, student)
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

## internal/service/student.go (+14 -3)

```diff
@@ -2,22 +2,33 @@
 
 import (
 	"context"
+	"log/slog"
 
 	pb "github.com/yylego/kratos-examples/demo1kratos/api/student"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/biz"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 type StudentService struct {
 	pb.UnimplementedStudentServiceServer
 
-	uc *biz.StudentUsecase
+	uc  *biz.StudentUsecase
+	log *slog.Logger
 }
 
-func NewStudentService(uc *biz.StudentUsecase) *StudentService {
-	return &StudentService{uc: uc}
+func NewStudentService(uc *biz.StudentUsecase, logger *slog.Logger) *StudentService {
+	return &StudentService{
+		uc:  uc,
+		log: logger,
+	}
 }
 
 func (s *StudentService) CreateStudent(ctx context.Context, req *pb.CreateStudentRequest) (*pb.CreateStudentReply, error) {
+	// Demo GetTraceID feature from tracekratos
+	// 演示 tracekratos 的 GetTraceID 功能
+	traceID := tracekratos.GetTraceID(ctx)
+	s.log.InfoContext(ctx, "Processing request with trace ID", "trace_id", traceID)
+
 	if req.Name == "" {
 		return nil, pb.ErrorBadParam("NAME IS REQUIRED")
 	}
```

