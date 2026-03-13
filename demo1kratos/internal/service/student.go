package service

import (
	"context"

	"github.com/go-kratos/kratos/v2/log"
	pb "github.com/yylego/kratos-examples/demo1kratos/api/student"
	"github.com/yylego/kratos-examples/demo1kratos/internal/biz"
	"github.com/yylego/kratos-trace/tracekratos"
)

type StudentService struct {
	pb.UnimplementedStudentServiceServer

	uc  *biz.StudentUsecase
	log *log.Helper
}

func NewStudentService(uc *biz.StudentUsecase, logger log.Logger) *StudentService {
	return &StudentService{
		uc:  uc,
		log: log.NewHelper(logger),
	}
}

func (s *StudentService) CreateStudent(ctx context.Context, req *pb.CreateStudentRequest) (*pb.CreateStudentReply, error) {
	// Demo GetTraceID feature from tracekratos
	// 演示 tracekratos 的 GetTraceID 功能
	traceID := tracekratos.GetTraceID(ctx)
	s.log.WithContext(ctx).Infof("Processing request with trace ID: %s", traceID)

	v, ebz := s.uc.CreateStudent(ctx, nil)
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.CreateStudentReply{Student: &pb.StudentInfo{Id: v.ID, Name: v.Name, Age: v.Age, ClassName: v.ClassName}}, nil
}

func (s *StudentService) UpdateStudent(ctx context.Context, req *pb.UpdateStudentRequest) (*pb.UpdateStudentReply, error) {
	v, ebz := s.uc.UpdateStudent(ctx, nil)
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.UpdateStudentReply{Student: &pb.StudentInfo{Id: v.ID, Name: v.Name, Age: v.Age, ClassName: v.ClassName}}, nil
}

func (s *StudentService) DeleteStudent(ctx context.Context, req *pb.DeleteStudentRequest) (*pb.DeleteStudentReply, error) {
	if ebz := s.uc.DeleteStudent(ctx, req.Id); ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.DeleteStudentReply{Success: true}, nil
}

func (s *StudentService) GetStudent(ctx context.Context, req *pb.GetStudentRequest) (*pb.GetStudentReply, error) {
	v, ebz := s.uc.GetStudent(ctx, req.Id)
	if ebz != nil {
		return nil, ebz.Erk
	}
	return &pb.GetStudentReply{Student: &pb.StudentInfo{Id: v.ID, Name: v.Name, Age: v.Age, ClassName: v.ClassName}}, nil
}

func (s *StudentService) ListStudents(ctx context.Context, req *pb.ListStudentsRequest) (*pb.ListStudentsReply, error) {
	students, count, ebz := s.uc.ListStudents(ctx, req.Page, req.PageSize)
	if ebz != nil {
		return nil, ebz.Erk
	}
	items := make([]*pb.StudentInfo, 0, len(students))
	for _, v := range students {
		items = append(items, &pb.StudentInfo{Id: v.ID, Name: v.Name, Age: v.Age, ClassName: v.ClassName})
	}
	return &pb.ListStudentsReply{Students: items, Count: count}, nil
}
