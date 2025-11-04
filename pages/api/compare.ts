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
    const startTime = Date.now();
    const { prompt } = req.body;

    if (!prompt || typeof prompt !== 'string') {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    if (prompt.length > 10000) {
      return res.status(400).json({ error: 'Prompt is too long (max 10000 characters)' });
    }

    console.log(`[Compare API] Starting comparison for prompt: "${prompt.substring(0, 50)}..."`);
    
    // Get responses from all three models in parallel
    const aiStartTime = Date.now();
    const responses = await compareModels(prompt);
    const aiEndTime = Date.now();
    
    console.log(`[Compare API] AI models completed in ${aiEndTime - aiStartTime}ms`);
    console.log(`[Compare API] Individual times: ${responses.map(r => `${r.modelName}: ${r.responseTimeMs}ms`).join(', ')}`);

    // Return response immediately
    const totalTime = Date.now() - startTime;
    console.log(`[Compare API] Sending response after ${totalTime}ms`);
    
    res.status(200).json({
      responses,
      serverTotalTime: totalTime,
    });

    // Save to database asynchronously (don't block response)
    const dbStartTime = Date.now();
    saveComparison(
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
    ).then(() => {
      console.log(`[Compare API] Database save completed in ${Date.now() - dbStartTime}ms`);
    }).catch((err) => {
      console.error('[Compare API] Failed to save comparison:', err);
    });
  } catch (error: any) {
    console.error('Error in compare API:', error);
    res.status(500).json({ 
      error: 'Failed to compare models',
      details: error.message 
    });
  }
}
