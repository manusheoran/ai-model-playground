import type { NextApiRequest, NextApiResponse } from 'next';
import { getComparisonHistory } from '@/lib/db';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const limit = parseInt(req.query.limit as string) || 20;
    const history = await getComparisonHistory(limit);
    
    res.status(200).json(history);
  } catch (error: any) {
    console.error('Error fetching history:', error);
    res.status(500).json({ 
      error: 'Failed to fetch history',
      details: error.message 
    });
  }
}
