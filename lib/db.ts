import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export interface Comparison {
  id: string;
  prompt: string;
  created_at: Date;
}

export interface ModelResponse {
  id: string;
  comparison_id: string;
  model_name: string;
  response_text: string;
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
  response_time_ms: number;
  estimated_cost: number;
  error?: string;
  created_at: Date;
}

export async function initDatabase() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS comparisons (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        prompt TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query(`
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
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_model_responses_comparison 
      ON model_responses(comparison_id);
    `);
  } finally {
    client.release();
  }
}

export async function saveComparison(
  prompt: string,
  responses: Array<{
    modelName: string;
    responseText?: string;
    promptTokens: number;
    completionTokens: number;
    totalTokens: number;
    responseTimeMs: number;
    estimatedCost: number;
    error?: string;
  }>
): Promise<string> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const comparisonResult = await client.query(
      'INSERT INTO comparisons (prompt) VALUES ($1) RETURNING id',
      [prompt]
    );
    const comparisonId = comparisonResult.rows[0].id;

    for (const response of responses) {
      await client.query(
        `INSERT INTO model_responses 
        (comparison_id, model_name, response_text, prompt_tokens, 
         completion_tokens, total_tokens, response_time_ms, estimated_cost, error)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          comparisonId,
          response.modelName,
          response.responseText,
          response.promptTokens,
          response.completionTokens,
          response.totalTokens,
          response.responseTimeMs,
          response.estimatedCost,
          response.error,
        ]
      );
    }

    await client.query('COMMIT');
    return comparisonId;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getComparisonHistory(limit = 20): Promise<
  Array<{
    comparison: Comparison;
    responses: ModelResponse[];
  }>
> {
  const client = await pool.connect();
  try {
    const comparisonsResult = await client.query(
      'SELECT * FROM comparisons ORDER BY created_at DESC LIMIT $1',
      [limit]
    );

    const history = [];
    for (const comparison of comparisonsResult.rows) {
      const responsesResult = await client.query(
        'SELECT * FROM model_responses WHERE comparison_id = $1 ORDER BY model_name',
        [comparison.id]
      );
      history.push({
        comparison,
        responses: responsesResult.rows,
      });
    }

    return history;
  } finally {
    client.release();
  }
}

export async function getComparisonById(id: string): Promise<{
  comparison: Comparison;
  responses: ModelResponse[];
} | null> {
  const client = await pool.connect();
  try {
    const comparisonResult = await client.query(
      'SELECT * FROM comparisons WHERE id = $1',
      [id]
    );

    if (comparisonResult.rows.length === 0) {
      return null;
    }

    const responsesResult = await client.query(
      'SELECT * FROM model_responses WHERE comparison_id = $1 ORDER BY model_name',
      [id]
    );

    return {
      comparison: comparisonResult.rows[0],
      responses: responsesResult.rows,
    };
  } finally {
    client.release();
  }
}

export { pool };
