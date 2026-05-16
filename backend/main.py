import os
import logging
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Load environment variables from .env
load_dotenv()

# Configure logging for debugging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Read configuration from .env
USE_MOCK = os.getenv("USE_MOCK", "true").lower() == "true"

# Import handlers based on mode
if USE_MOCK:
    from mock_handler import get_mock_dialogue
    logger.info("🎭 Running in MOCK mode")
else:
    from llm_handler import get_llm_dialogue
    logger.info("🤖 Running in LLM mode with Ollama")

# Initialize FastAPI app
app = FastAPI(
    title="Divinus Backend",
    description="NPC dialogue generation for the Divinus god game",
    version="1.0.0"
)

# Enable CORS for Godot frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (adjust for production)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request/Response models with validation
class DialogueRequest(BaseModel):
    """Incoming request to generate NPC dialogue"""
    npc_id: int = Field(..., gt=0, description="Unique NPC identifier")
    state: str = Field(..., min_length=1, description="NPC emotional state (e.g., 'witness', 'grateful')")
    boon_cast: str = Field(..., min_length=1, description="Divine miracle cast (e.g., 'heal', 'bless')")
    day: int = Field(..., ge=1, description="Current game day")

class DialogueResponse(BaseModel):
    """Response with generated NPC dialogue"""
    dialogue: str = Field(..., description="NPC's reaction (max 20 words)")
    faith_bonus: int = Field(..., ge=5, le=20, description="Faith gained from reaction")

# Health check endpoint
@app.get("/health")
async def health():
    """Health check for deployment monitoring"""
    return {"status": "ok"}

# Main dialogue generation endpoint
@app.post("/npc/dialogue", response_model=DialogueResponse)
async def npc_dialogue(request: DialogueRequest) -> DialogueResponse:
    """
    Generate NPC dialogue in response to a divine miracle.

    Routes to mock_handler (deterministic for testing) or
    llm_handler (AI-generated using Ollama phi3:mini).
    """
    try:
        # Route to appropriate handler based on .env configuration
        if USE_MOCK:
            result = get_mock_dialogue(
                request.npc_id,
                request.state,
                request.boon_cast,
                request.day
            )
        else:
            result = get_llm_dialogue(
                request.npc_id,
                request.state,
                request.boon_cast,
                request.day
            )

        # Validate response matches schema
        response = DialogueResponse(**result)
        logger.info(f"NPC {request.npc_id}: faith_bonus={response.faith_bonus}")
        return response

    except Exception as e:
        logger.error(f"Error generating dialogue: {e}")
        raise

# Run server if executed directly
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
