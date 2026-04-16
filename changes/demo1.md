# Changes

Code differences compared to source project.

## cmd/demo1kratos/main.go (+2 -0)

```diff
@@ -13,6 +13,7 @@
 	"github.com/go-kratos/kratos/v2/transport/http"
 	"github.com/yylego/done"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/conf"
+	"github.com/yylego/kratos-trace/tracekratos"
 	"github.com/yylego/must"
 	"github.com/yylego/rese"
 )
@@ -55,6 +56,7 @@
 		"service.version", Version,
 		"trace.id", tracing.TraceID(),
 		"span.id", tracing.SpanID(),
+		"request-trace", tracekratos.LogTraceID(), // 我们自己的 trace ID，与官方 trace.id 并行
 	)
 	c := config.New(
 		config.WithSource(
```

## cmd/demo1kratos/wire_gen.go (+1 -1)

```diff
@@ -24,7 +24,7 @@
 		return nil, nil, err
 	}
 	studentUsecase := biz.NewStudentUsecase(dataData, logger)
-	studentService := service.NewStudentService(studentUsecase)
+	studentService := service.NewStudentService(studentUsecase, logger)
 	grpcServer := server.NewGRPCServer(confServer, studentService, logger)
 	httpServer := server.NewHTTPServer(confServer, studentService, logger)
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
 	pb "github.com/yylego/kratos-examples/demo1kratos/api/student"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/conf"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/service"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 func NewHTTPServer(c *conf.Server, student *service.StudentService, logger log.Logger) *http.Server {
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
 	pb.RegisterStudentServiceHTTPServer(srv, student)
 	return srv
+}
+
+func NewTraceMiddleware(logger log.Logger) middleware.Middleware {
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
@@ -3,21 +3,32 @@
 import (
 	"context"
 
+	"github.com/go-kratos/kratos/v2/log"
 	pb "github.com/yylego/kratos-examples/demo1kratos/api/student"
 	"github.com/yylego/kratos-examples/demo1kratos/internal/biz"
+	"github.com/yylego/kratos-trace/tracekratos"
 )
 
 type StudentService struct {
 	pb.UnimplementedStudentServiceServer
 
-	uc *biz.StudentUsecase
+	uc  *biz.StudentUsecase
+	log *log.Helper
 }
 
-func NewStudentService(uc *biz.StudentUsecase) *StudentService {
-	return &StudentService{uc: uc}
+func NewStudentService(uc *biz.StudentUsecase, logger log.Logger) *StudentService {
+	return &StudentService{
+		uc:  uc,
+		log: log.NewHelper(logger),
+	}
 }
 
 func (s *StudentService) CreateStudent(ctx context.Context, req *pb.CreateStudentRequest) (*pb.CreateStudentReply, error) {
+	// Demo GetTraceID feature from tracekratos
+	// 演示 tracekratos 的 GetTraceID 功能
+	traceID := tracekratos.GetTraceID(ctx)
+	s.log.WithContext(ctx).Infof("Processing request with trace ID: %s", traceID)
+
 	if req.Name == "" {
 		return nil, pb.ErrorBadParam("NAME IS REQUIRED")
 	}
```

