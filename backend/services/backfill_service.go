package services

import (
	"fmt"

	"gorm.io/gorm"
)

func BackfillHomeownerStatusID(db *gorm.DB) error {
	if db == nil {
		return fmt.Errorf("db is nil")
	}

	result := db.Exec(`
WITH latest_docs AS (
	SELECT DISTINCT ON (user_id) user_id, status
	FROM verification_documents
	WHERE LOWER(document_group) IN ('government_id','homeowner_id')
	ORDER BY user_id, created_at DESC, id DESC
)
UPDATE homeowner_profiles AS hp
SET status_id = latest_docs.status
FROM latest_docs
WHERE hp.user_id = latest_docs.user_id
  AND (hp.status_id IS NULL OR hp.status_id = '' OR hp.status_id <> latest_docs.status);
`)

	return result.Error
}
