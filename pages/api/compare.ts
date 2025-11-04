import type { NextApiRequest, NextApiResponse } from 'next';
import { compareModels } from '@/lib/ai-service';
import { saveComparison } from '@/lib/db';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { prompt } = req.body;

    if (!prompt || typeof prompt !== 'string') {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    if (prompt.length > 10000) {
      return res.status(400).json({ error: 'Prompt is too long (max 10000 characters)' });
    }

    // Get responses from all three models in parallel
    const responses = await compareModels(prompt);

    // Save to database
    const comparisonId = await saveComparison(
      prompt,
      responses.map((r) => ({
        modelName: r.modelName,
        responseText: r.responseText,
        promptTokens: r.promptTokens,
        completionTokens: r.completionTokens,
        totalTokens: r.totalTokens,
        responseTimeMs: r.responseTimeMs,
        estimatedCost: r.estimatedCost,
        error: r.error,
      }))
    );

    res.status(200).json({
      comparisonId,
      responses,
    });
  } catch (error: any) {
    console.error('Error in compare API:', error);
    res.status(500).json({ 
      error: 'Failed to compare models',
      details: error.message 
    });
  }
}
