package biz

import (
	"context"

	"github.com/brianvoe/gofakeit/v7"
	"github.com/go-kratos/kratos/v2/log"
	"github.com/yylego/kratos-ebz/ebzkratos"
	demo1student "github.com/yylego/kratos-examples/demo1kratos/api/student"
	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
	"github.com/yylego/kratos-examples/demo2kratos/internal/data"
)

type Article struct {
	ID        int64
	Title     string
	Content   string
	StudentID int64
}

type ArticleUsecase struct {
	data            *data.Data
	demo1HttpClient *data.Demo1HttpClient
	log             *log.Helper
}

func NewArticleUsecase(data *data.Data, demo1HttpClient *data.Demo1HttpClient, logger log.Logger) *ArticleUsecase {
	return &ArticleUsecase{data: data, demo1HttpClient: demo1HttpClient, log: log.NewHelper(logger)}
}

func (uc *ArticleUsecase) CreateArticle(ctx context.Context, a *Article) (*Article, *ebzkratos.Ebz) {
	var res Article
	if err := gofakeit.Struct(&res); err != nil {
		return nil, ebzkratos.New(pb.ErrorArticleCreateFailure("fake: %v", err))
	}
	// 跨服务调用 demo1kratos，trace ID 会通过 HTTP header 传播
	resp, err := uc.demo1HttpClient.GetStudentClient().CreateStudent(ctx, &demo1student.CreateStudentRequest{
		Name: res.Title,
	})
	if err != nil {
		return nil, ebzkratos.New(pb.ErrorServerError("http: %v", err))
	}
	res.Title = "message:[http-resp:" + resp.GetStudent().GetName() + "]"
	return &res, nil
}

func (uc *ArticleUsecase) UpdateArticle(ctx context.Context, a *Article) (*Article, *ebzkratos.Ebz) {
	var res Article
	if err := gofakeit.Struct(&res); err != nil {
		return nil, ebzkratos.New(pb.ErrorServerError("fake: %v", err))
	}
	return &res, nil
}

func (uc *ArticleUsecase) DeleteArticle(ctx context.Context, id int64) *ebzkratos.Ebz {
	return nil
}

func (uc *ArticleUsecase) GetArticle(ctx context.Context, id int64) (*Article, *ebzkratos.Ebz) {
	var res Article
	if err := gofakeit.Struct(&res); err != nil {
		return nil, ebzkratos.New(pb.ErrorServerError("fake: %v", err))
	}
	return &res, nil
}

func (uc *ArticleUsecase) ListArticles(ctx context.Context, page int32, pageSize int32) ([]*Article, int32, *ebzkratos.Ebz) {
	var items []*Article
	gofakeit.Slice(&items)
	return items, int32(len(items)), nil
}
