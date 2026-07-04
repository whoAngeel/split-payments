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
	SmallURL     string `json:"small_url"`
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

	// Tres variantes: thumb (avatares), small (cards en listas) y medium
	// (detalle). Content-addressed por UUID: nunca cambian, el proxy los
	// cachea como inmutables.
	variants := []struct {
		suffix  string
		img     image.Image
		quality int
	}{
		{"_thumb.jpg", imaging.Fill(img, 200, 200, imaging.Center, imaging.Lanczos), 72},
		{"_small.jpg", imaging.Fit(img, 400, 400, imaging.Lanczos), 80},
		{"_medium.jpg", imaging.Fit(img, 800, 800, imaging.Lanczos), 85},
	}

	urls := make(map[string]string, len(variants))
	for _, v := range variants {
		var buf bytes.Buffer
		if err := imaging.Encode(&buf, v.img, imaging.JPEG, imaging.JPEGQuality(v.quality)); err != nil {
			return nil, fmt.Errorf("encoding %s: %w", v.suffix, err)
		}
		key := base + v.suffix
		if _, err := s.client.PutObject(ctx, s.bucket, key, &buf, int64(buf.Len()), minio.PutObjectOptions{
			ContentType: "image/jpeg",
		}); err != nil {
			return nil, fmt.Errorf("uploading %s: %w", v.suffix, err)
		}
		urls[v.suffix] = "/" + s.bucket + "/" + key
	}

	return &UploadResult{
		ThumbnailURL: urls["_thumb.jpg"],
		SmallURL:     urls["_small.jpg"],
		MediumURL:    urls["_medium.jpg"],
	}, nil
}

func (s *UploadService) MinioClient() *minio.Client { return s.client }
func (s *UploadService) MinioBucket() string         { return s.bucket }
