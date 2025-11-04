import type { NextApiRequest, NextApiResponse } from 'next';
import { getComparisonById } from '@/lib/db';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { id } = req.query;

    if (!id || typeof id !== 'string') {
      return res.status(400).json({ error: 'Invalid comparison ID' });
    }

    const comparison = await getComparisonById(id);

    if (!comparison) {
      return res.status(404).json({ error: 'Comparison not found' });
    }

    res.status(200).json(comparison);
  } catch (error: any) {
    console.error('Error fetching comparison:', error);
    res.status(500).json({ 
      error: 'Failed to fetch comparison',
      details: error.message 
    });
  }
}
