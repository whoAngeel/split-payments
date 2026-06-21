package service

import (
	"bytes"
	"context"
	"fmt"
	"image"
	"io"
	"path/filepath"
	"strings"

	"github.com/disintegration/imaging"
	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type UploadService struct {
	client *minio.Client
	bucket string
}

func NewUploadService(endpoint, accessKey, secretKey, bucket string) (*UploadService, error) {
	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure: false,
	})
	if err != nil {
		return nil, fmt.Errorf("creating minio client: %w", err)
	}

	ctx := context.Background()
	exists, err := client.BucketExists(ctx, bucket)
	if err != nil {
		return nil, fmt.Errorf("checking bucket: %w", err)
	}
	if !exists {
		if err := client.MakeBucket(ctx, bucket, minio.MakeBucketOptions{}); err != nil {
			return nil, fmt.Errorf("creating bucket: %w", err)
		}
	}

	return &UploadService{client: client, bucket: bucket}, nil
}

type UploadResult struct {
	ThumbnailURL string `json:"thumbnail_url"`
	MediumURL    string `json:"medium_url"`
}

func (s *UploadService) Upload(ctx context.Context, reader io.Reader, filename, prefix string) (*UploadResult, error) {
	img, _, err := image.Decode(reader)
	if err != nil {
		return nil, fmt.Errorf("decoding image: %w", err)
	}

	id := uuid.New().String()
	ext := strings.TrimPrefix(filepath.Ext(filename), ".")
	if ext == "" {
		ext = "webp"
	}

	base := prefix + "/" + id

	thumb := imaging.Fill(img, 200, 200, imaging.Center, imaging.Lanczos)
	medium := imaging.Fit(img, 800, 800, imaging.Lanczos)

	thumbKey := base + "_thumb.jpg"
	mediumKey := base + "_medium.jpg"

	var thumbBuf, mediumBuf bytes.Buffer
	if err := imaging.Encode(&thumbBuf, thumb, imaging.JPEG, imaging.JPEGQuality(72)); err != nil {
		return nil, fmt.Errorf("encoding thumb: %w", err)
	}
	if err := imaging.Encode(&mediumBuf, medium, imaging.JPEG, imaging.JPEGQuality(85)); err != nil {
		return nil, fmt.Errorf("encoding medium: %w", err)
	}

	if _, err := s.client.PutObject(ctx, s.bucket, thumbKey, &thumbBuf, int64(thumbBuf.Len()), minio.PutObjectOptions{
		ContentType: "image/jpeg",
	}); err != nil {
		return nil, fmt.Errorf("uploading thumb: %w", err)
	}

	if _, err := s.client.PutObject(ctx, s.bucket, mediumKey, &mediumBuf, int64(mediumBuf.Len()), minio.PutObjectOptions{
		ContentType: "image/jpeg",
	}); err != nil {
		return nil, fmt.Errorf("uploading medium: %w", err)
	}

	return &UploadResult{
		ThumbnailURL: "/" + s.bucket + "/" + thumbKey,
		MediumURL:    "/" + s.bucket + "/" + mediumKey,
	}, nil
}

func (s *UploadService) MinioClient() *minio.Client { return s.client }
func (s *UploadService) MinioBucket() string         { return s.bucket }
