package service

import (
	"context"

	"github.com/go-kratos/kratos/v2/log"
	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
	"github.com/yylego/kratos-examples/demo2kratos/internal/biz"
	"github.com/yylego/kratos-trace/tracekratos"
)

type ArticleService struct {
	pb.UnimplementedArticleServiceServer

	uc  *biz.ArticleUsecase
	log *log.Helper
}

func NewArticleService(uc *biz.ArticleUsecase, logger log.Logger) *ArticleService {
	return &ArticleService{
		uc:  uc,
		log: log.NewHelper(logger),
	}
}

func (s *ArticleService) CreateArticle(ctx context.Context, req *pb.CreateArticleRequest) (*pb.CreateArticleReply, error) {
	// Demo GetTraceID feature from tracekratos
	// 演示 tracekratos 的 GetTraceID 功能
	traceID := tracekratos.GetTraceID(ctx)
	s.log.WithContext(ctx).Infof("Processing request with trace ID: %s", traceID)

	v, ebz := s.uc.CreateArticle(ctx, nil)
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.CreateArticleReply{Article: &pb.ArticleInfo{Id: v.ID, Title: v.Title, Content: v.Content, StudentId: v.StudentID}}, nil
}

func (s *ArticleService) UpdateArticle(ctx context.Context, req *pb.UpdateArticleRequest) (*pb.UpdateArticleReply, error) {
	v, ebz := s.uc.UpdateArticle(ctx, nil)
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.UpdateArticleReply{Article: &pb.ArticleInfo{Id: v.ID, Title: v.Title, Content: v.Content, StudentId: v.StudentID}}, nil
}

func (s *ArticleService) DeleteArticle(ctx context.Context, req *pb.DeleteArticleRequest) (*pb.DeleteArticleReply, error) {
	if ebz := s.uc.DeleteArticle(ctx, req.Id); ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.DeleteArticleReply{Success: true}, nil
}

func (s *ArticleService) GetArticle(ctx context.Context, req *pb.GetArticleRequest) (*pb.GetArticleReply, error) {
	v, ebz := s.uc.GetArticle(ctx, req.Id)
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.GetArticleReply{Article: &pb.ArticleInfo{Id: v.ID, Title: v.Title, Content: v.Content, StudentId: v.StudentID}}, nil
}

func (s *ArticleService) ListArticles(ctx context.Context, req *pb.ListArticlesRequest) (*pb.ListArticlesReply, error) {
	articles, count, ebz := s.uc.ListArticles(ctx, req.Page, req.PageSize)
	if ebz != nil {
		return nil, ebz.Erk
	}
	items := make([]*pb.ArticleInfo, 0, len(articles))
	for _, v := range articles {
		items = append(items, &pb.ArticleInfo{Id: v.ID, Title: v.Title, Content: v.Content, StudentId: v.StudentID})
	}
	return &pb.ListArticlesReply{Articles: items, Count: count}, nil
}
