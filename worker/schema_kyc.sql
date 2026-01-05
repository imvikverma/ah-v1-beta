-- KYC Documents Table for DigiLocker Integration
-- Run with: wrangler d1 execute aurum-harmony-db --file=worker/schema_kyc.sql

-- KYC Documents table
CREATE TABLE IF NOT EXISTS kyc_documents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    document_type TEXT NOT NULL,  -- AADHAAR, PAN, etc.
    document_number TEXT,  -- Masked: XXXX-XXXX-1234 for Aadhaar, full PAN
    document_name TEXT,
    document_uri TEXT,  -- DigiLocker document URI
    document_url TEXT,  -- Encrypted storage URL (if downloaded)
    verified INTEGER DEFAULT 0 NOT NULL,  -- 0 = false, 1 = true
    verification_date TEXT,
    verification_method TEXT,  -- DIGILOCKER, MANUAL, etc.
    digilocker_doc_uri TEXT,  -- DigiLocker reference URI
    metadata TEXT,  -- JSON metadata (name, dob, address, etc.)
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_document_type ON kyc_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_verified ON kyc_documents(verified);

-- Add KYC fields to users table
-- Note: Run this migration separately if users table already exists
-- ALTER TABLE users ADD COLUMN kyc_verified INTEGER DEFAULT 0 NOT NULL;
-- ALTER TABLE users ADD COLUMN kyc_verified_at TEXT;
-- ALTER TABLE users ADD COLUMN kyc_verification_method TEXT;
-- ALTER TABLE users ADD COLUMN digilocker_access_token TEXT;  -- Encrypted
-- ALTER TABLE users ADD COLUMN digilocker_refresh_token TEXT;  -- Encrypted
-- ALTER TABLE users ADD COLUMN digilocker_token_expires_at TEXT;
