package services

import (
	"fmt"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"
<<<<<<< HEAD

	"fixit-backend/models"
=======
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
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

<<<<<<< HEAD
func UploadRootDir() string {
	if configured := strings.TrimSpace(os.Getenv("UPLOAD_DIR")); configured != "" {
		if filepath.IsAbs(configured) {
			return filepath.Clean(configured)
		}
		if abs, err := filepath.Abs(configured); err == nil {
			return filepath.Clean(abs)
		}
		return filepath.Clean(configured)
	}

	if cwd, err := os.Getwd(); err == nil {
		if filepath.Base(cwd) == "backend" {
			return filepath.Join(cwd, "uploads")
		}
		if _, err := os.Stat(filepath.Join(cwd, "backend")); err == nil {
			return filepath.Join(cwd, "backend", "uploads")
		}
		return filepath.Join(cwd, "uploads")
	}

	return "uploads"
}

func ResolveDocumentFilePath(doc models.VerificationDocument) string {
	seen := map[string]bool{}
	candidates := make([]string, 0, 12)
	addCandidate := func(path string) {
		clean := filepath.Clean(strings.TrimSpace(path))
		if clean == "" || clean == "." || seen[clean] {
			return
		}
		seen[clean] = true
		candidates = append(candidates, clean)
	}

	addCandidate(doc.FilePath)
	if trimmed := strings.TrimSpace(doc.FilePath); trimmed != "" && !filepath.IsAbs(trimmed) {
		addCandidate(filepath.Join(UploadRootDir(), trimmed))
		addCandidate(filepath.Join(filepath.Dir(UploadRootDir()), trimmed))
	}

	if storedName := strings.TrimSpace(doc.StoredName); storedName != "" {
		group := strings.ToLower(strings.TrimSpace(doc.DocumentGroup))
		switch group {
		case "government_id", "homeowner_id":
			addCandidate(filepath.Join(UploadRootDir(), "homeowners", "ids", storedName))
			addCandidate(filepath.Join(UploadRootDir(), "tradespeople", "government_ids", storedName))
		case "license", "tradesperson_license":
			addCandidate(filepath.Join(UploadRootDir(), "tradespeople", "licenses", storedName))
		}
	}

	for _, candidate := range candidates {
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	return ""
}

func SaveUploadedFile(file multipart.File, header *multipart.FileHeader, relativeDir string) (string, string, error) {
	ext := strings.ToLower(filepath.Ext(header.Filename))
	storedName := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	directory := filepath.Join(UploadRootDir(), relativeDir)
=======
func SaveUploadedFile(file multipart.File, header *multipart.FileHeader, relativeDir string) (string, string, error) {
	ext := strings.ToLower(filepath.Ext(header.Filename))
	storedName := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	directory := filepath.Join("uploads", relativeDir)
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe

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
<<<<<<< HEAD
}
=======
}
>>>>>>> f0d4a22e6fea9d12bc1190946d9e81ce85a01ebe
