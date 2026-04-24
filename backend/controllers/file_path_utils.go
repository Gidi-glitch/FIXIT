package controllers

import (
	"os"
	"path/filepath"
	"strings"
)

func publicUploadRelativePath(filePath string) string {
	cleaned := filepath.ToSlash(strings.TrimSpace(filePath))
	cleaned = strings.TrimPrefix(cleaned, "./")
	cleaned = strings.TrimPrefix(cleaned, "/")

	if cleaned == "" {
		return ""
	}

	if idx := strings.Index(cleaned, "/uploads/"); idx >= 0 {
		return strings.TrimPrefix(cleaned[idx+1:], "uploads/")
	}

	switch {
	case strings.HasPrefix(cleaned, "uploads/"):
		return strings.TrimPrefix(cleaned, "uploads/")
	case strings.HasPrefix(cleaned, "backend/uploads/"):
		return strings.TrimPrefix(cleaned, "backend/uploads/")
	case strings.HasPrefix(cleaned, "backend/"):
		remainder := strings.TrimPrefix(cleaned, "backend/")
		if strings.HasPrefix(remainder, "uploads/") {
			return strings.TrimPrefix(remainder, "uploads/")
		}
	}

	if idx := strings.Index(cleaned, "uploads/"); idx >= 0 {
		return cleaned[idx+len("uploads/"):]
	}

	return cleaned
}

func resolveStoredUploadPath(filePath string) string {
	cleaned := filepath.ToSlash(strings.TrimSpace(filePath))
	if cleaned == "" {
		return ""
	}

	rel := publicUploadRelativePath(cleaned)
	candidates := []string{
		cleaned,
		strings.TrimPrefix(cleaned, "./"),
		strings.TrimPrefix(cleaned, "/"),
	}

	if rel != "" {
		candidates = append(candidates,
			filepath.Join("uploads", rel),
			filepath.Join("backend", "uploads", rel),
			filepath.Join("..", "uploads", rel),
		)
	}

	seen := map[string]bool{}
	for _, candidate := range candidates {
		if candidate == "" || seen[candidate] {
			continue
		}
		seen[candidate] = true

		info, err := os.Stat(candidate)
		if err == nil && !info.IsDir() {
			return candidate
		}
	}

	if rel != "" {
		return filepath.Join("uploads", rel)
	}

	return cleaned
}
