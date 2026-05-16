import random
import logging

logger = logging.getLogger(__name__)

# 10 hardcoded villager reactions to divine miracles
# These are used when USE_MOCK=true (no Ollama required)
VILLAGER_REACTIONS = [
    # Reaction 1: Healing theme
    {"dialogue": "The light... it healed me! By the gods!", "faith_bonus": 18},

    # Reaction 2: Awe and wonder
    {"dialogue": "I feel blessed by divine power!", "faith_bonus": 20},

    # Reaction 3: Gratitude
    {"dialogue": "My prayers have been answered! Thank the heavens!", "faith_bonus": 19},

    # Reaction 4: Reverence
    {"dialogue": "Such power can only be divine. I am humbled.", "faith_bonus": 17},

    # Reaction 5: Relief
    {"dialogue": "At last! The gods have not abandoned us!", "faith_bonus": 15},

    # Reaction 6: Wonder
    {"dialogue": "The sky opened with light... I have seen divinity.", "faith_bonus": 16},

    # Reaction 7: Conversion
    {"dialogue": "I doubted, but now I believe. Forgive me!", "faith_bonus": 14},

    # Reaction 8: Devotion
    {"dialogue": "This miracle... it fills my heart with faith eternal.", "faith_bonus": 19},

    # Reaction 9: Hope
    {"dialogue": "A sign! The gods still watch over us!", "faith_bonus": 12},

    # Reaction 10: Conviction
    {"dialogue": "Miracles are real. I shall follow forever now.", "faith_bonus": 13},
]

def get_mock_dialogue(npc_id: int, state: str, boon_cast: str, day: int) -> dict:
    """
    Return a random hardcoded villager reaction.

    Used for testing without requiring Ollama.
    Arguments npc_id, state, boon_cast, day are informational
    but not used in mock mode (reactions are deterministic).

    Args:
        npc_id: NPC identifier (unused in mock)
        state: NPC emotional state (unused in mock)
        boon_cast: Divine boon cast (unused in mock)
        day: Current game day (unused in mock)

    Returns:
        dict with keys "dialogue" (str) and "faith_bonus" (int 5-20)
    """
    # Select random reaction
    reaction = random.choice(VILLAGER_REACTIONS)

    logger.info(f"Mock dialogue for NPC {npc_id}: faith_bonus={reaction['faith_bonus']}")

    return reaction
