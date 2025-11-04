# AI Model Playground

A full-stack application with a Next.js backend and a Flutter mobile app that lets you compare responses from three AI models side‑by‑side: **GPT-4o (OpenAI)**, **Claude 3.5 Sonnet (Anthropic)**, and **Grok Beta (XAi)**.

## Features

- **Three-Panel Comparison**: View responses from all three models simultaneously
- **Performance Metrics**: Track response time, token usage, and estimated costs
- **Comparison History**: Save and review past comparisons
- **Modern Mobile UI**: Built with Flutter (Material Design)
- **Parallel Processing**: All API calls execute concurrently for faster results
- **Error Handling**: Independent error handling for each model
- **Responsive Design**: Works seamlessly on desktop and mobile devices

## Architecture

### Backend
- **Next.js API Routes**: Serverless functions for backend logic
- **PostgreSQL**: Database for storing comparison history
- **AI Gateway**: Unified API interface using Vercel AI Gateway
- **Parallel Request Processing**: Async/await with Promise.allSettled for concurrent API calls

### Frontend (Mobile)
- **Flutter**: UI framework
- **Dart**: Programming language
- **GetX**: State management and navigation
- **Google Fonts**: Typography
- **http**: REST client

### Database Schema

```sql
-- Comparisons table
CREATE TABLE comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Model responses table
CREATE TABLE model_responses (
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
```

## Setup Instructions

### Prerequisites
- Node.js 18+ and npm/yarn
- PostgreSQL database (local or cloud)

### Installation

1. **Clone the repository**
   ```bash
   cd ai_model_playground
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   
   Update `.env.local` with your database URL:
   ```env
   AI_GATEWAY_API_KEY= $YOUR_KEY
   AI_GATEWAY_URL=https://ai-gateway.vercel.sh/v1/chat/completions
   DATABASE_URL= $PATH_TO_YOUR_DB
   ```

4. **Set up the database**
   
   Create a PostgreSQL database:
   ```bash
   createdb ai_playground
   ```
   
   Initialize the schema by calling the API:
   ```bash
   # Start the dev server
   npm run dev
   
   # In another terminal, initialize the database
   curl -X POST http://localhost:3000/api/init-db
   ```

5. **Start the development server**
   ```bash
   npm run dev
   ```

6. **Open the application**
   
   Navigate to [http://localhost:3000](http://localhost:3000)

### Run the Flutter Mobile App

1. Ensure the backend is running at http://localhost:3000
2. Update the mobile API base URL if needed:
   - `mobile/lib/services/api_service.dart` (use `http://10.0.2.2:3000` for Android Emulator)
3. From the `mobile/` directory:
   ```bash
   flutter pub get
   flutter run
   ```

## Deployment

### Vercel (Recommended)

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Deploy**
   ```bash
   vercel
   ```

3. **Set environment variables** in the Vercel dashboard:
   - `AI_GATEWAY_API_KEY`
   - `AI_GATEWAY_URL`
   - `DATABASE_URL`

4. **Initialize database** after deployment:
   ```bash
   curl -X POST https://your-app.vercel.app/api/init-db
   ```

### Alternative Deployment Options
- **Netlify**: Supports Next.js with serverless functions
- **Railway**: Easy PostgreSQL + Next.js deployment
- **Render**: Full-stack deployment with managed PostgreSQL

## API Endpoints

### POST `/api/compare`
Compare responses from all three models.

**Request:**
```json
{
  "prompt": "Explain quantum computing in simple terms"
}
```

**Response:**
```json
{
  "comparisonId": "uuid",
  "responses": [
    {
      "modelId": "openai/gpt-4o",
      "modelName": "GPT-4o",
      "provider": "OpenAI",
      "responseText": "...",
      "promptTokens": 10,
      "completionTokens": 150,
      "totalTokens": 160,
      "responseTimeMs": 2500,
      "estimatedCost": 0.002475
    },
    // ... other models
  ]
}
```

### GET `/api/history`
Get comparison history.

**Query Parameters:**
- `limit` (optional): Number of results (default: 20)

### GET `/api/comparison/[id]`
Get a specific comparison by ID.

## Technical Decisions & Tradeoffs

### 1. **Unified AI Gateway**
- **Decision**: Use Vercel AI Gateway instead of direct API integrations
- **Benefits**: Simplified API interface, unified error handling, built-in rate limiting
- **Tradeoffs**: Dependency on third-party service, less control over request customization

### 2. **PostgreSQL for Persistence**
- **Decision**: Use PostgreSQL for storing comparison history
- **Benefits**: ACID compliance, relational data modeling, powerful querying
- **Tradeoffs**: Requires database setup, not as simple as file-based storage

### 3. **Token Estimation vs. Accurate Counting**
- **Decision**: Use simple character-based estimation with fallback to API usage data
- **Benefits**: Fast, no additional dependencies during execution
- **Tradeoffs**: Slightly less accurate than tiktoken library
- **Note**: The tiktoken library is included for future enhancement

### 4. **Promise.allSettled for Parallel Requests**
- **Decision**: Use Promise.allSettled instead of Promise.all
- **Benefits**: All requests complete even if some fail, better error isolation
- **Tradeoffs**: Slightly more complex error handling

### 5. **Server-Side API Calls**
- **Decision**: API calls through Next.js API routes (not client-side)
- **Benefits**: API key security, CORS avoidance, centralized error handling
- **Tradeoffs**: Additional latency from extra hop

### 6. **No Real-Time Streaming**
- **Decision**: Non-streaming responses for simplicity
- **Benefits**: Easier comparison, complete responses viewable together
- **Tradeoffs**: Higher perceived latency, no progressive rendering

## Cost Estimation

Current pricing (as of implementation):
- **GPT-4o**: $0.005/1K input tokens, $0.015/1K output tokens
- **Claude 3.5 Sonnet**: $0.003/1K input tokens, $0.015/1K output tokens
- **Grok Beta**: $0.005/1K input tokens, $0.015/1K output tokens

Costs are calculated per request and displayed in the UI.

## Future Improvements

1. **Streaming Responses**: Implement SSE for real-time response streaming
2. **More Models**: Add support for additional models (Gemini, Mistral, etc.)
3. **Custom Configurations**: Allow temperature, max_tokens, and other parameter adjustments
4. **Response Comparison Tools**: Add diff view, side-by-side highlighting
5. **Export Functionality**: Export comparisons as PDF, JSON, or Markdown
6. **User Authentication**: Add user accounts and private comparison history
7. **Advanced Analytics**: Token usage trends, cost analysis over time
8. **Model Benchmarking**: Automated quality scoring and performance metrics
9. **Prompt Templates**: Save and reuse common prompts
10. **Collaborative Features**: Share comparisons with team members

## Project Structure

```
ai_model_playground/
├── lib/                      # Backend core (Node/Next.js)
│   ├── ai-service.ts         # AI Gateway integration
│   └── db.ts                 # Database operations
├── pages/
│   ├── api/
│   │   ├── compare.ts        # Main comparison endpoint
│   │   ├── history.ts        # History retrieval
│   │   ├── comparison/[id].ts # Single comparison
│   │   └── init-db.ts        # Database initialization
│   ├── index.tsx             # (Optional) Web UI entry if present
│   └── history.tsx           # (Optional) Web history page
├── mobile/                   # Flutter mobile app
│   ├── lib/
│   │   ├── controllers/      # GetX controllers (e.g., ComparisonController)
│   │   ├── screens/          # Flutter screens (HomeScreen, HistoryScreen)
│   │   ├── widgets/          # UI widgets (ModelCardWidget)
│   │   └── services/         # API client (api_service.dart)
│   └── pubspec.yaml
├── scripts/
│   └── init-db.sql           # Database schema
├── .env.local                # Environment variables
├── package.json              # Dependencies
└── README.md                 # Documentation
```

## Development

### Run Tests
```bash
npm test
```

### Build for Production
```bash
npm run build
npm start
```

### Lint Code
```bash
npm run lint
```

## Troubleshooting

### Database Connection Issues
- Ensure PostgreSQL is running
- Verify `DATABASE_URL` in `.env.local`
- Check firewall/network settings

### API Gateway Errors
- Verify `AI_GATEWAY_API_KEY` is valid
- Check API rate limits
- Review error messages in browser console

### Build Errors
- Clear `.next` folder: `rm -rf .next`
- Reinstall dependencies: `rm -rf node_modules && npm install`

## License

MIT License - Feel free to use this project for learning or commercial purposes.

## Credits

Built with:
- [Next.js](https://nextjs.org/)
- [Flutter](https://flutter.dev/)
- [PostgreSQL](https://www.postgresql.org/)
- [Vercel AI Gateway](https://vercel.com/)
