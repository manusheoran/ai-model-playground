# Technical Architecture

## Overview

AI Model Playground is a full-stack Next.js application that enables side-by-side comparison of responses from three leading AI models: GPT-4o (OpenAI), Claude 3.5 Sonnet (Anthropic), and Grok Beta (XAi).

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend (Flutter)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Prompt      │  │  Model Card  │  │  History     │      │
│  │  Input       │  │  Component   │  │  Page        │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTP Requests
┌────────────────────────────▼────────────────────────────────┐
│                    Next.js API Routes                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  /api/       │  │  /api/       │  │  /api/       │      │
│  │  compare     │  │  history     │  │  init-db     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
    ┌─────▼──────┐    ┌─────▼──────┐    ┌─────▼──────┐
    │ AI Service │    │ Database   │    │ Database   │
    │ Layer      │    │ Queries    │    │ Init       │
    └─────┬──────┘    └─────┬──────┘    └────────────┘
          │                  │
    ┌─────▼──────────────────▼──────┐
    │   External Services            │
    │  ┌──────────┐  ┌────────────┐ │
    │  │ Vercel   │  │ PostgreSQL │ │
    │  │ AI       │  │ Database   │ │
    │  │ Gateway  │  │            │ │
    │  └──────────┘  └────────────┘ │
    └────────────────────────────────┘
```

## Technology Stack

### Frontend
- **Flutter**: Mobile UI framework
- **Dart**: Programming language
- **GetX**: State management and navigation
- **Google Fonts**: Typography
- **http**: REST client for API calls

### Backend
- **Next.js 14**: Full-stack React framework
- **API Routes**: Serverless functions
- **Node.js**: Runtime environment

### Database
- **PostgreSQL**: Relational database
- **pg**: Node.js PostgreSQL client
- **Connection Pooling**: Efficient connection management

### AI Integration
- **Vercel AI Gateway**: Unified API interface
- **OpenAI GPT-4o**: Advanced language model
- **Anthropic Claude 3.5 Sonnet**: Context-aware model
- **XAi Grok Beta**: Alternative AI model

## Component Architecture

### Frontend Components

#### 1. **Prompt Area (HomeScreen)** (`mobile/lib/screens/home_screen.dart`)
 - Multiline `TextField` for prompt entry
 - Character counter and example prompts (chips)
 - Compare button with loading state using GetX observables
 - Calls `ComparisonController.compareModels()` which invokes the backend API

#### 2. **ModelCardWidget** (`mobile/lib/widgets/model_card_widget.dart`)
 - Displays model header (name/provider) with gradient branding
 - Scrollable response content area
 - Compact metrics footer: response time, cost, tokens, in/out
 - Handles loading and error states per model

### Mobile Screens

#### 1. **HomeScreen** (`mobile/lib/screens/home_screen.dart`)
 - Main comparison interface
 - Prompt input, actions, and horizontal list of `ModelCardWidget`
 - Real-time loading/error state via GetX

#### 2. **HistoryScreen** (`mobile/lib/screens/history_screen.dart`)
 - Displays past comparisons fetched from backend
 - Shows metrics and allows browsing previous runs

### API Routes

#### 1. **POST /api/compare**
Main comparison endpoint that coordinates parallel AI requests.

**Flow:**
1. Validates incoming prompt
2. Calls `compareModels()` from AI service
3. Saves results to database
4. Returns responses to client

**Request:**
```typescript
{
  prompt: string; // max 10,000 characters
}
```

**Response:**
```typescript
{
  comparisonId: string;
  responses: ModelResponse[];
}
```

#### 2. **GET /api/history**
Retrieves comparison history.

**Query Parameters:**
- `limit`: Number of results (default: 20)

**Response:**
```typescript
{
  comparison: Comparison;
  responses: ModelResponse[];
}[]
```

#### 3. **GET /api/comparison/[id]**
Retrieves a specific comparison.

#### 4. **POST /api/init-db**
Initializes database schema.

## Core Services

### AI Service (`lib/ai-service.ts`)

#### Model Configuration
```typescript
interface AIModel {
  id: string;                    // API identifier
  name: string;                  // Display name
  provider: string;              // Provider name
  inputCostPer1kTokens: number;  // Pricing
  outputCostPer1kTokens: number; // Pricing
}
```

#### Parallel Request Processing
```typescript
async function compareModels(prompt: string): Promise<ModelResponse[]> {
  const promises = AI_MODELS.map(model => callAIModel(model, prompt));
  const results = await Promise.allSettled(promises);
  return processResults(results);
}
```

**Key Features:**
- **Concurrent Execution**: All three models called simultaneously
- **Error Isolation**: Individual model failures don't affect others
- **Timeout Handling**: 30-second timeout per model
- **Cost Calculation**: Real-time cost estimation

### Database Service (`lib/db.ts`)

#### Connection Pooling
```typescript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

#### Key Operations

**saveComparison()**
- Atomic transaction
- Saves comparison and all responses
- Rollback on error

**getComparisonHistory()**
- Paginated results
- Ordered by creation date
- Joins comparison with responses

**getComparisonById()**
- Single comparison lookup
- Includes all model responses

## Data Flow

### Comparison Request Flow

```
User Input
    ↓
PromptInput Component
    ↓
POST /api/compare
    ↓
compareModels() [AI Service]
    ↓
Promise.allSettled([
    callAIModel(GPT-4o),
    callAIModel(Claude),
    callAIModel(Grok)
]) ← Parallel Execution
    ↓
Process Results
    ↓
saveComparison() [Database]
    ↓
Return Response
    ↓
Update UI (3 ModelCards)
```

### History Retrieval Flow

```
History Page Load
    ↓
useEffect Hook
    ↓
GET /api/history
    ↓
getComparisonHistory() [Database]
    ↓
SQL Query with JOIN
    ↓
Format Results
    ↓
Return to Client
    ↓
Render History List
```

## Performance Optimizations

### 1. **Parallel API Calls**
All three AI models are queried simultaneously using `Promise.allSettled()`, reducing total response time from O(3n) to O(n).

### 2. **Connection Pooling**
Database connections are pooled and reused, avoiding the overhead of creating new connections for each request.

### 3. **Indexed Queries**
Database queries use indexes on frequently accessed columns:
- `comparison_id` for responses
- `created_at` for history ordering

### 4. **Async/Await**
Non-blocking I/O operations ensure the server can handle multiple concurrent requests.

### 5. **Error Boundaries**
Each model's request is isolated, preventing cascade failures.

## Error Handling Strategy

### API Level
```typescript
try {
  const response = await axios.post(url, data);
  return processSuccess(response);
} catch (error) {
  return processError(error);
}
```

### Database Level
```typescript
const client = await pool.connect();
try {
  await client.query('BEGIN');
  // ... operations
  await client.query('COMMIT');
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

### UI Level
```typescript
{error && (
  <ErrorMessage error={error} />
)}

{response.error ? (
  <ErrorDisplay error={response.error} />
) : (
  <SuccessDisplay data={response.data} />
)}
```

## Security Considerations

### 1. **API Key Protection**
- Keys stored in environment variables
- Never exposed to client
- Server-side API calls only

### 2. **Input Validation**
- Prompt length limits (10,000 chars)
- Type checking with TypeScript
- SQL injection prevention via parameterized queries

### 3. **Database Security**
- Connection string in environment variables
- Parameterized queries (pg library)
- Transaction isolation

### 4. **CORS**
- Same-origin policy enforced
- API routes not exposed to external origins

### 5. **Rate Limiting**
- Implement rate limiting per IP (future enhancement)
- API Gateway handles provider-level limits

## Scalability Considerations

### Horizontal Scaling
- **Stateless API routes**: Can scale across multiple instances
- **Database connection pooling**: Prevents connection exhaustion
- **External state**: All state in database, not in-memory

### Vertical Scaling
- **Database**: Upgrade to larger instance for more connections
- **Compute**: Increase serverless function memory/timeout

### Caching Strategy (Future)
```typescript
// Redis cache for frequent prompts
const cached = await redis.get(`comparison:${promptHash}`);
if (cached) return JSON.parse(cached);

// ... fetch and cache
await redis.setex(`comparison:${promptHash}`, 3600, JSON.stringify(result));
```

## Monitoring & Observability

### Metrics to Track
1. **Response Times**: Per model and total
2. **Token Usage**: Daily/weekly aggregates
3. **Cost**: Running total per model
4. **Error Rates**: By model and type
5. **Database Performance**: Query times, connection pool usage

### Logging Strategy
```typescript
console.log('[API] Compare request:', { promptLength, timestamp });
console.error('[AI Service] Model error:', { model, error, timestamp });
```

### Production Monitoring
- Use Vercel Analytics for frontend metrics
- Implement structured logging
- Set up error tracking (Sentry)
- Database monitoring (pg_stat_statements)

## Testing Strategy

### Unit Tests
```javascript
// Test AI service
describe('compareModels', () => {
  it('should call all three models in parallel', async () => {
    const result = await compareModels('test prompt');
    expect(result).toHaveLength(3);
  });
});
```

### Integration Tests
```javascript
// Test API endpoints
describe('POST /api/compare', () => {
  it('should return responses from all models', async () => {
    const response = await request(app)
      .post('/api/compare')
      .send({ prompt: 'test' });
    expect(response.status).toBe(200);
  });
});
```

### E2E Tests
```javascript
// Test user flow with Playwright
test('user can compare models', async ({ page }) => {
  await page.goto('/');
  await page.fill('textarea', 'test prompt');
  await page.click('button[type="submit"]');
  await expect(page.locator('.model-card')).toHaveCount(3);
});
```

## Deployment Architecture

### Vercel Deployment
```
┌─────────────────────────────────┐
│   Vercel Edge Network (CDN)     │
│                                 │
│  ┌──────────────────────────┐  │
│  │   Static Assets          │  │
│  │   (CSS, JS, Images)      │  │
│  └──────────────────────────┘  │
│                                 │
│  ┌──────────────────────────┐  │
│  │   Serverless Functions   │  │
│  │   (API Routes)           │  │
│  └───────────┬──────────────┘  │
└──────────────┼─────────────────┘
               │
        ┌──────▼──────┐
        │  PostgreSQL │
        │  Database   │
        └─────────────┘
```

## Future Enhancements

### Phase 1: Core Improvements
- [ ] Streaming responses (SSE)
- [ ] More models (Gemini, Mistral)
- [ ] Custom parameters (temperature, max_tokens)
- [ ] Better token counting (tiktoken integration)

### Phase 2: Advanced Features
- [ ] Response comparison tools (diff view)
- [ ] User authentication
- [ ] Prompt templates library
- [ ] Export functionality (PDF, JSON)

### Phase 3: Analytics
- [ ] Usage analytics dashboard
- [ ] Cost breakdown by model
- [ ] Performance benchmarking
- [ ] Quality scoring

### Phase 4: Collaboration
- [ ] Team workspaces
- [ ] Shared comparison libraries
- [ ] Comment system
- [ ] API access for integration

## Conclusion

The AI Model Playground demonstrates a well-architected full-stack application with:
- Clean separation of concerns
- Scalable architecture
- Robust error handling
- Performance optimization
- Security best practices

The modular design allows for easy extension with additional models, features, and integrations.
