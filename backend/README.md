# Divinus Backend — Day 1 Starter

FastAPI backend for the Divinus god game. Generates NPC dialogue in response to divine miracles using either mock responses or AI (Ollama phi3:mini).

## 🚀 Quick Start

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Setup Environment
```bash
# Copy template to .env
cp .env.example .env

# Default is mock mode (no Ollama needed)
# .env already has USE_MOCK=true
```

### 3. Run Server

**Mock Mode** (fastest, no GPU required):
```bash
USE_MOCK=true uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Real Mode** (requires Ollama):

Terminal 1 - Start Ollama service:
```bash
ollama serve
```

Terminal 2 - Start backend (edit .env: USE_MOCK=false):
```bash
USE_MOCK=false uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 🧪 Test the API

### Health Check
```bash
curl -X GET http://localhost:8000/health
```

Expected output:
```json
{"status": "ok"}
```

### Generate NPC Dialogue

```bash
curl -X POST http://localhost:8000/npc/dialogue \
  -H "Content-Type: application/json" \
  -d '{
    "npc_id": 1,
    "state": "witness",
    "boon_cast": "heal",
    "day": 1
  }'
```

Expected output (mock mode):
```json
{
  "dialogue": "The light... it healed me! By the gods!",
  "faith_bonus": 18
}
```

## 📁 File Structure

- **main.py** — FastAPI app, CORS, endpoints, routing
- **mock_handler.py** — 10 hardcoded villager reactions
- **llm_handler.py** — Ollama integration with phi3:mini
- **requirements.txt** — Python dependencies
- **.env.example** — Configuration template
- **README.md** — This file

## 🔧 Configuration

Edit `.env` to switch modes:

```env
USE_MOCK=true              # Mock mode (fast, no GPU)
USE_MOCK=false             # Real mode (requires Ollama)

OLLAMA_HOST=http://localhost:11434
```

## 🤖 Setting Up Ollama (Real Mode)

1. Download Ollama: https://ollama.ai
2. Pull the model:
   ```bash
   ollama pull phi3:mini
   ```
3. Start Ollama service:
   ```bash
   ollama serve
   ```
4. Edit `.env`: `USE_MOCK=false`
5. Restart backend

## 📊 Response Format

All dialogue responses include:
- `dialogue` (string, max 20 words): NPC's reaction
- `faith_bonus` (int 5-20): Faith gained from reaction

## 🛡️ Error Handling

- If Ollama fails to connect, backend automatically falls back to mock mode
- Invalid JSON from LLM triggers fallback to mock
- Missing fields in response triggers fallback to mock
- faith_bonus is clamped to 5–20 range

## 🔌 CORS

CORS is enabled for all origins (development). Restrict for production:
```python
allow_origins=["http://localhost:8000"]  # Your Godot app URL
```

## 📝 Logging

Check console output for debug info. Modify in main.py:
```python
logging.basicConfig(level=logging.DEBUG)  # More verbose
```

## 🎯 Next Steps

- Integrate with Godot 4 frontend
- Add database persistence
- Implement more NPC states and boons
- Fine-tune system prompt for better responses
- Add rate limiting and authentication
