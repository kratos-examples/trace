package server

import (
	"context"
	"strconv"
	"time"

	"github.com/go-kratos/kratos/v2/log"
	"github.com/go-kratos/kratos/v2/middleware"
	"github.com/go-kratos/kratos/v2/middleware/logging"
	"github.com/go-kratos/kratos/v2/middleware/recovery"
	"github.com/go-kratos/kratos/v2/transport/http"
	"github.com/google/uuid"
	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
	"github.com/yylego/kratos-examples/demo2kratos/internal/conf"
	"github.com/yylego/kratos-examples/demo2kratos/internal/service"
	"github.com/yylego/kratos-trace/tracekratos"
)

func NewHTTPServer(c *conf.Server, article *service.ArticleService, logger log.Logger) *http.Server {
	var opts = []http.ServerOption{
		http.Middleware(
			recovery.Recovery(),
			NewTraceMiddleware(logger), //在请求逻辑执行前打印日志，显示请求参数和追踪信息
			logging.Server(logger),     //在请求逻辑执行后打印日志，显示执行结果的错误码和状态码
		),
	}
	if c.Http.Network != "" {
		opts = append(opts, http.Network(c.Http.Network))
	}
	if c.Http.Address != "" {
		opts = append(opts, http.Address(c.Http.Address))
	}
	if c.Http.Timeout != nil {
		opts = append(opts, http.Timeout(c.Http.Timeout.AsDuration()))
	}
	srv := http.NewServer(opts...)
	pb.RegisterArticleServiceHTTPServer(srv, article)
	return srv
}

func NewTraceMiddleware(logger log.Logger) middleware.Middleware {
	// Demo tracekratos features using function options
	// 演示 tracekratos 的功能选项
	config := tracekratos.NewConfig("TRACE_ID",
		tracekratos.WithLogLevel(log.LevelInfo),
		tracekratos.WithLogReply(true),
		tracekratos.WithNewTraceID(func(ctx context.Context) string {
			return "TRACE-ID-" + strconv.FormatInt(time.Now().UnixNano(), 10) + "-" + uuid.New().String() + "-BBB"
		}),
		tracekratos.WithFormatArgs(func(req any) string {
			return tracekratos.ExtractArgs(req)
		}),
	)
	return tracekratos.NewTraceMiddleware(config, logger)
}
