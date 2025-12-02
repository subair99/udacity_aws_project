-- 1. Drop existing table and indexes
DROP TABLE IF EXISTS bedrock_integration.bedrock_kb CASCADE;

-- 2. Create table
CREATE TABLE bedrock_integration.bedrock_kb (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    embedding VECTOR(1024),
    chunks TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create HNSW index (REQUIRED by Bedrock) - NOT ivfflat!
CREATE INDEX bedrock_kb_embedding_idx 
ON bedrock_integration.bedrock_kb 
USING hnsw (embedding vector_cosine_ops);

-- 4. Create full-text search index (still required)
CREATE INDEX bedrock_kb_chunks_fts_idx 
ON bedrock_integration.bedrock_kb 
USING gin (to_tsvector('simple', chunks));

-- 5. Optional: Metadata index
CREATE INDEX bedrock_kb_metadata_idx 
ON bedrock_integration.bedrock_kb 
USING gin (metadata);

-- 6. Grant permissions
GRANT USAGE ON SCHEMA bedrock_integration TO dbadmin, bedrock_user, rdsadmin;
GRANT ALL ON TABLE bedrock_integration.bedrock_kb TO dbadmin, bedrock_user, rdsadmin;