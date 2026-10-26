# Local Storage and Data Model

## Storage principles
- SQLite for metadata and local search indexes.
- Managed filesystem storage for app-owned originals/derivatives and temporary files.
- OS document picker for external imports.
- No silent whole-device indexing.
- Preserve original files by default.
- Use stable IDs, not filenames, as primary identifiers.

## Suggested tables

### documents
`id`, `title`, `managed_path`, `mime_type`, `byte_size`, `page_count`, `created_at`, `updated_at`, `is_favorite`, `folder_id`, `source_kind`, `processing_status`.

### pages
`id`, `document_id`, `page_index`, `source_image_path`, `rotation`, `crop_json`, `enhancement_preset`, `created_at`.

### folders
`id`, `name`, `parent_id`, `created_at`.

### tags and document_tags
Stable tag IDs and a many-to-many relation.

### ocr_results
`id`, `document_id`, `page_id`, `language`, `text`, `engine_version`, `created_at`, `status`.

### processing_jobs
`id`, `operation`, `input_refs`, `temporary_path`, `status`, `progress`, `error_code`, `created_at`, `updated_at`.

Use migrations and indexes based on query patterns. Avoid persisting passwords or raw signature data unless there is a documented need and approved secure storage design.

## Safe file operations
- Validate available space before expensive jobs where feasible.
- Write to a unique temporary location.
- Flush/close outputs and validate them before final commit.
- Prefer atomic rename/replace where supported.
- Never overwrite a source by default.
- On startup, reconcile incomplete jobs and stale temporary files.
- If metadata commit fails after file output, provide recovery/reconciliation logic.
- Handle duplicate names and Unicode paths.

## Deletion
Clearly distinguish removing a library reference from deleting a managed file. When deleting a document, also remove related OCR text, thumbnails and index records according to documented behavior. Explain that files exported outside app-managed storage may need to be deleted separately by the user.

## Encryption at rest
If a private folder is implemented, use established platform-backed key management and vetted encryption libraries. Define key recovery and data-loss consequences. Do not invent custom cryptography. A device passcode/app lock alone does not automatically encrypt all files.
