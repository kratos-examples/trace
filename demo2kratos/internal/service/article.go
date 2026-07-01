package service

import (
	"context"
	"log/slog"

	pb "github.com/yylego/kratos-examples/demo2kratos/api/article"
	"github.com/yylego/kratos-examples/demo2kratos/internal/biz"
	"github.com/yylego/kratos-trace/tracekratos"
)

type ArticleService struct {
	pb.UnimplementedArticleServiceServer

	uc  *biz.ArticleUsecase
	log *slog.Logger
}

func NewArticleService(uc *biz.ArticleUsecase, logger *slog.Logger) *ArticleService {
	return &ArticleService{
		uc:  uc,
		log: logger,
	}
}

func (s *ArticleService) CreateArticle(ctx context.Context, req *pb.CreateArticleRequest) (*pb.CreateArticleReply, error) {
	// Demo GetTraceID feature from tracekratos
	// 演示 tracekratos 的 GetTraceID 功能
	traceID := tracekratos.GetTraceID(ctx)
	s.log.InfoContext(ctx, "Processing request with trace ID", "trace_id", traceID)

	if req.Title == "" {
		return nil, pb.ErrorBadParam("TITLE IS REQUIRED")
	}
	if req.StudentId <= 0 {
		return nil, pb.ErrorBadParam("STUDENT_ID IS REQUIRED")
	}
	v, ebz := s.uc.CreateArticle(ctx, &biz.Article{
		Title:     req.Title,
		Content:   req.Content,
		StudentID: req.StudentId,
	})
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.CreateArticleReply{Article: &pb.ArticleInfo{Id: v.ID, Title: v.Title, Content: v.Content, StudentId: v.StudentID}}, nil
}

func (s *ArticleService) UpdateArticle(ctx context.Context, req *pb.UpdateArticleRequest) (*pb.UpdateArticleReply, error) {
	if req.Id <= 0 {
		return nil, pb.ErrorBadParam("ID IS REQUIRED")
	}
	if req.Title == "" {
		return nil, pb.ErrorBadParam("TITLE IS REQUIRED")
	}
	if req.StudentId <= 0 {
		return nil, pb.ErrorBadParam("STUDENT_ID IS REQUIRED")
	}
	v, ebz := s.uc.UpdateArticle(ctx, &biz.Article{
		ID:        req.Id,
		Title:     req.Title,
		Content:   req.Content,
		StudentID: req.StudentId,
	})
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.UpdateArticleReply{Article: &pb.ArticleInfo{Id: v.ID, Title: v.Title, Content: v.Content, StudentId: v.StudentID}}, nil
}

func (s *ArticleService) DeleteArticle(ctx context.Context, req *pb.DeleteArticleRequest) (*pb.DeleteArticleReply, error) {
	if req.Id <= 0 {
		return nil, pb.ErrorBadParam("ID IS REQUIRED")
	}
	if ebz := s.uc.DeleteArticle(ctx, req.Id); ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.DeleteArticleReply{Success: true}, nil
}

func (s *ArticleService) GetArticle(ctx context.Context, req *pb.GetArticleRequest) (*pb.GetArticleReply, error) {
	if req.Id <= 0 {
		return nil, pb.ErrorBadParam("ID IS REQUIRED")
	}
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

func (s *ArticleService) ListStudentArticles(ctx context.Context, req *pb.ListStudentArticlesRequest) (*pb.ListArticlesReply, error) {
	if req.StudentId <= 0 {
		return nil, pb.ErrorBadParam("STUDENT_ID IS REQUIRED")
	}
	articles, count, ebz := s.uc.ListStudentArticles(ctx, req.StudentId, req.Page, req.PageSize)
	if ebz != nil {
		return nil, ebz.Erk
	}
	items := make([]*pb.ArticleInfo, 0, len(articles))
	for _, v := range articles {
		items = append(items, &pb.ArticleInfo{Id: v.ID, Title: v.Title, Content: v.Content, StudentId: v.StudentID})
	}
	return &pb.ListArticlesReply{Articles: items, Count: count}, nil
}
