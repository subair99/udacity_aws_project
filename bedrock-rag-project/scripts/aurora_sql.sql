-- 1. Install pgvector extension FIRST (required before creating vector columns)
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Drop existing table and indexes
DROP TABLE IF EXISTS bedrock_integration.bedrock_kb CASCADE;

-- 3. Create schema
CREATE SCHEMA IF NOT EXISTS bedrock_integration;

-- 4. Create table with UUID id (Bedrock expects UUID)
CREATE TABLE bedrock_integration.bedrock_kb (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    embedding VECTOR(1024),       -- Make sure this matches your embedding model
    chunks TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create HNSW index (REQUIRED by Bedrock for vector search)
CREATE INDEX bedrock_kb_embedding_idx 
ON bedrock_integration.bedrock_kb 
USING hnsw (embedding vector_cosine_ops);

-- 6. CREATE FULL-TEXT SEARCH INDEX (REQUIRED by Bedrock - this is what's missing!)
CREATE INDEX bedrock_kb_chunks_idx 
ON bedrock_integration.bedrock_kb 
USING gin (to_tsvector('english', chunks));

-- 7. Optional: Metadata index for better performance
CREATE INDEX bedrock_kb_metadata_idx 
ON bedrock_integration.bedrock_kb 
USING gin (metadata);

-- 8. Grant permissions (Bedrock needs SELECT, INSERT, UPDATE, DELETE)
GRANT USAGE ON SCHEMA bedrock_integration TO dbadmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON bedrock_integration.bedrock_kb TO dbadmin;