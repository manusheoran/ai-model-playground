-- Create the database (run this manually)
-- CREATE DATABASE ai_playground;

-- Connect to the database
-- \c ai_playground;

-- Create comparisons table
CREATE TABLE IF NOT EXISTS comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create model_responses table
CREATE TABLE IF NOT EXISTS model_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comparison_id UUID REFERENCES comparisons(id) ON DELETE CASCADE,
  model_name VARCHAR(100) NOT NULL,
  response_text TEXT,
  prompt_tokens INTEGER,
  completion_tokens INTEGER,
  total_tokens INTEGER,
  response_time_ms INTEGER,
  estimated_cost DECIMAL(10, 6),
  error TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_model_responses_comparison 
ON model_responses(comparison_id);

-- Create index for ordering by creation date
CREATE INDEX IF NOT EXISTS idx_comparisons_created_at 
ON comparisons(created_at DESC);
