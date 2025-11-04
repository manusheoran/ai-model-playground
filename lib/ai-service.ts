import axios from 'axios';
import { encoding_for_model } from 'tiktoken';

export interface AIModel {
  id: string;
  name: string;
  provider: string;
  inputCostPer1kTokens: number;
  outputCostPer1kTokens: number;
}

export const AI_MODELS: AIModel[] = [
  {
    id: 'openai/gpt-4o',
    name: 'GPT-4o',
    provider: 'OpenAI',
    inputCostPer1kTokens: 0.005,
    outputCostPer1kTokens: 0.015,
  },
  {
    id: 'anthropic/claude-3-5-sonnet-20241022',
    name: 'Claude 3.5 Sonnet',
    provider: 'Anthropic',
    inputCostPer1kTokens: 0.003,
    outputCostPer1kTokens: 0.015,
  },
  {
    id: 'xai/grok-beta',
    name: 'Grok Beta',
    provider: 'XAi',
    inputCostPer1kTokens: 0.005,
    outputCostPer1kTokens: 0.015,
  },
];

export interface ModelResponse {
  modelId: string;
  modelName: string;
  provider: string;
  responseText: string;
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  responseTimeMs: number;
  estimatedCost: number;
  error?: string;
}

function estimateTokens(text: string): number {
  // Simple estimation: ~4 characters per token for most models
  // For production, use tiktoken for accurate counting
  return Math.ceil(text.length / 4);
}

function calculateCost(
  promptTokens: number,
  completionTokens: number,
  model: AIModel
): number {
  const promptCost = (promptTokens / 1000) * model.inputCostPer1kTokens;
  const completionCost = (completionTokens / 1000) * model.outputCostPer1kTokens;
  return promptCost + completionCost;
}

async function callAIModel(
  model: AIModel,
  prompt: string
): Promise<ModelResponse> {
  const startTime = Date.now();
  
  try {
    const response = await axios.post(
      process.env.AI_GATEWAY_URL || 'https://ai-gateway.vercel.sh/v1/chat/completions',
      {
        model: model.id,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
        stream: false,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.AI_GATEWAY_API_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000, // 30 second timeout
      }
    );

    const responseTimeMs = Date.now() - startTime;
    const usage = response.data.usage || {};
    const promptTokens = usage.prompt_tokens || estimateTokens(prompt);
    const completionTokens = usage.completion_tokens || estimateTokens(response.data.choices[0].message.content);
    const totalTokens = usage.total_tokens || (promptTokens + completionTokens);

    return {
      modelId: model.id,
      modelName: model.name,
      provider: model.provider,
      responseText: response.data.choices[0].message.content,
      promptTokens,
      completionTokens,
      totalTokens,
      responseTimeMs,
      estimatedCost: calculateCost(promptTokens, completionTokens, model),
    };
  } catch (error: any) {
    const responseTimeMs = Date.now() - startTime;
    const promptTokens = estimateTokens(prompt);
    
    return {
      modelId: model.id,
      modelName: model.name,
      provider: model.provider,
      responseText: '',
      promptTokens,
      completionTokens: 0,
      totalTokens: promptTokens,
      responseTimeMs,
      estimatedCost: 0,
      error: error.response?.data?.error?.message || error.message || 'Unknown error occurred',
    };
  }
}

export async function compareModels(prompt: string): Promise<ModelResponse[]> {
  // Call all three models in parallel
  const promises = AI_MODELS.map((model) => callAIModel(model, prompt));
  
  // Use Promise.allSettled to ensure all requests complete even if some fail
  const results = await Promise.allSettled(promises);
  
  return results.map((result, index) => {
    if (result.status === 'fulfilled') {
      return result.value;
    } else {
      // Handle rejected promise
      const model = AI_MODELS[index];
      const promptTokens = estimateTokens(prompt);
      return {
        modelId: model.id,
        modelName: model.name,
        provider: model.provider,
        responseText: '',
        promptTokens,
        completionTokens: 0,
        totalTokens: promptTokens,
        responseTimeMs: 0,
        estimatedCost: 0,
        error: result.reason?.message || 'Request failed',
      };
    }
  });
}
