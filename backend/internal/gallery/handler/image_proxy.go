package handler

import (
	"io"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/minio/minio-go/v7"
)

type ImageProxyHandler struct {
	client *minio.Client
	bucket string
}

func NewImageProxyHandler(client *minio.Client, bucket string) *ImageProxyHandler {
	return &ImageProxyHandler{client: client, bucket: bucket}
}

func (h *ImageProxyHandler) Serve(c *gin.Context) {
	objectName := strings.TrimPrefix(c.Param("filepath"), "/")
	if objectName == "" {
		c.Status(http.StatusNotFound)
		return
	}

	obj, err := h.client.GetObject(c.Request.Context(), h.bucket, objectName, minio.GetObjectOptions{})
	if err != nil {
		c.Status(http.StatusNotFound)
		return
	}
	defer obj.Close()

	info, err := obj.Stat()
	if err != nil {
		c.Status(http.StatusNotFound)
		return
	}

	contentType := info.ContentType
	if contentType == "" {
		if strings.HasSuffix(objectName, ".jpg") || strings.HasSuffix(objectName, ".jpeg") {
			contentType = "image/jpeg"
		} else if strings.HasSuffix(objectName, ".png") {
			contentType = "image/png"
		}
	}

	// Los objetos son content-addressed (UUID en el nombre): nunca cambian,
	// cache agresivo es seguro.
	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "public, max-age=31536000, immutable")
	if info.ETag != "" {
		c.Header("ETag", info.ETag)
		if match := c.GetHeader("If-None-Match"); match != "" && match == info.ETag {
			c.Status(http.StatusNotModified)
			return
		}
	}
	c.Status(http.StatusOK)
	io.Copy(c.Writer, obj)
}
