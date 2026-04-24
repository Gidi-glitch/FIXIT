package services

import (
	"fmt"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const MaxUploadSize int64 = 5 * 1024 * 1024

var allowedExtensions = map[string]bool{
	".pdf":  true,
	".jpg":  true,
	".jpeg": true,
	".png":  true,
}

func ValidateUpload(header *multipart.FileHeader) error {
	if header == nil {
		return fmt.Errorf("missing uploaded file")
	}

	if header.Size > MaxUploadSize {
		return fmt.Errorf("file exceeds 5MB limit")
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	if !allowedExtensions[ext] {
		return fmt.Errorf("unsupported file type")
	}

	return nil
}

func SaveUploadedFile(file multipart.File, header *multipart.FileHeader, relativeDir string) (string, string, error) {
	ext := strings.ToLower(filepath.Ext(header.Filename))
	storedName := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	directory := filepath.Join("uploads", relativeDir)

	if err := os.MkdirAll(directory, os.ModePerm); err != nil {
		return "", "", err
	}

	absolutePath := filepath.Join(directory, storedName)
	destination, err := os.Create(absolutePath)
	if err != nil {
		return "", "", err
	}
	defer destination.Close()

	if _, err = destination.ReadFrom(file); err != nil {
		return "", "", err
	}

	return storedName, filepath.ToSlash(absolutePath), nil
}
