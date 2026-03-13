package data

import (
	"context"

	"github.com/go-kratos/kratos/v2/log"
	"github.com/go-kratos/kratos/v2/middleware"
	"github.com/go-kratos/kratos/v2/transport/http"
	demo1student "github.com/yylego/kratos-examples/demo1kratos/api/student"
	"github.com/yylego/must"
	"github.com/yylego/rese"
)

type Demo1HttpClient struct {
	client        *http.Client
	studentClient demo1student.StudentServiceHTTPClient
}

func NewDemo1HttpClient(logger log.Logger) (*Demo1HttpClient, func()) {
	LOG := log.NewHelper(logger)

	// 直接连接 demo1kratos 的 HTTP 端口，trace ID 会通过 HTTP header 跨服务传播
	client := rese.P1(http.NewClient(
		context.Background(),
		http.WithEndpoint("http://127.0.0.1:8000"),
		http.WithMiddleware(func(handler middleware.Handler) middleware.Handler {
			LOG.Infof("handle http request in middleware")
			return func(ctx context.Context, req any) (any, error) {
				return handler(ctx, req)
			}
		}),
	))
	studentClient := demo1student.NewStudentServiceHTTPClient(client)
	cleanup := func() {
		must.Done(client.Close())
	}
	return &Demo1HttpClient{
		client:        client,
		studentClient: studentClient,
	}, cleanup
}

func (c *Demo1HttpClient) GetStudentClient() demo1student.StudentServiceHTTPClient {
	return c.studentClient
}
