import json
import logging
import os
from dotenv import load_dotenv

# Load environment variables for OLLAMA_HOST
load_dotenv()

logger = logging.getLogger(__name__)

# Import Ollama client (will call ollama API)
try:
    import ollama
except ImportError:
    logger.error("ollama library not installed. Run: pip install ollama")
    raise

# Configuration
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL_NAME = "phi3:mini"

# System prompt for the AI model
# This tells phi3 how to behave and what format to output
SYSTEM_PROMPT = """You are a villager in a god game. Respond in ONE sentence, in character, reacting to a divine miracle. Return only valid JSON with keys: 'dialogue' (string, max 20 words) and 'faith_bonus' (int between 5 and 20). Do not include markdown, code blocks, or extra text."""

def get_llm_dialogue(npc_id: int, state: str, boon_cast: str, day: int) -> dict:
    """
    Generate NPC dialogue using Ollama's phi3:mini model.

    Calls the local Ollama service with a system prompt and user message,
    parses the JSON response, and returns structured dialogue.
    Falls back to mock response on error.

    Args:
        npc_id: Unique NPC identifier
        state: Current NPC emotional state (e.g., "witness", "grateful")
        boon_cast: Divine miracle/boon cast (e.g., "heal", "bless")
        day: Current game day number

    Returns:
        dict with keys "dialogue" (str) and "faith_bonus" (int 5-20)

    Raises:
        Exception: If Ollama connection fails after retry
    """

    # Build the user message with game context
    user_message = f"State: {state}. Boon cast: {boon_cast}. Day: {day}. NPC ID: {npc_id}. React in one sentence."

    try:
        logger.info(f"Calling Ollama ({MODEL_NAME}) for NPC {npc_id}...")

        # Create Ollama client pointing to local service
        client = ollama.Client(host=OLLAMA_HOST)

        # Call Ollama with streaming disabled (we want complete response)
        response = client.generate(
            model=MODEL_NAME,
            prompt=user_message,
            system=SYSTEM_PROMPT,
            stream=False,
        )

        # Extract the generated text from Ollama response
        # response is a GenerateResponse object, not a dict
        if hasattr(response, 'response'):
            generated_text = response.response.strip()
        else:
            generated_text = response.get("response", "").strip()
        logger.debug(f"Ollama raw response: {generated_text}")

        # Parse the JSON response
        # phi3 may wrap JSON in markdown code blocks (```json ... ```)
        try:
            parsed = json.loads(generated_text)
        except json.JSONDecodeError as e:
            # If JSON parsing fails, try to extract JSON from the text
            logger.warning(f"Failed to parse JSON from Ollama: {e}")

            # Attempt to extract JSON using simple heuristics
            if "{" in generated_text and "}" in generated_text:
                json_start = generated_text.find("{")
                json_end = generated_text.rfind("}") + 1
                try:
                    parsed = json.loads(generated_text[json_start:json_end])
                except json.JSONDecodeError:
                    logger.error("Could not extract valid JSON from response")
                    # Fall back to mock on parse failure
                    from mock_handler import get_mock_dialogue
                    return get_mock_dialogue(npc_id, state, boon_cast, day)
            else:
                # No JSON found, fall back to mock
                from mock_handler import get_mock_dialogue
                return get_mock_dialogue(npc_id, state, boon_cast, day)

        # Validate required fields exist
        if "dialogue" not in parsed or "faith_bonus" not in parsed:
            logger.error("Missing required fields in LLM response")
            from mock_handler import get_mock_dialogue
            return get_mock_dialogue(npc_id, state, boon_cast, day)

        # Ensure faith_bonus is within valid range (5-20)
        faith_bonus = int(parsed["faith_bonus"])
        faith_bonus = max(5, min(20, faith_bonus))  # Clamp to range

        # Cap dialogue at 20 words (rough estimate: ~4 chars per word)
        dialogue = str(parsed["dialogue"])[:100]

        result = {
            "dialogue": dialogue,
            "faith_bonus": faith_bonus
        }

        logger.info(f"LLM response for NPC {npc_id}: faith_bonus={faith_bonus}")
        return result

    except Exception as e:
        # On any error (connection refused, model not found, etc.)
        logger.error(f"Ollama error: {e}")
        logger.info("Falling back to mock handler...")

        # Fall back to deterministic mock response
        from mock_handler import get_mock_dialogue
        return get_mock_dialogue(npc_id, state, boon_cast, day)
