# EventBus: Central event hub for all game systems
# All communication between game systems flows through signals defined here
# Autoload this as "EventBus" in project settings
extends Node

# === Game Events ===

# Emitted when god casts a boon at a position
signal boon_cast(boon_data: Dictionary, position: Vector2)

# Emitted when an NPC converts to a follower
signal npc_converted(npc: Node)

# Emitted when a shrine is built
signal shrine_built(shrine: Node)

# Emitted when an enemy is defeated
signal enemy_killed(enemy: Node)

# Emitted when the day cycle advances
signal day_changed(day_number: int)

# Emitted 30 seconds before the day ends — triggers enemy waves
signal day_ending(day_number: int)

# Emitted when an enemy spawns during a raid
signal enemy_spawned(position: Vector2)

# Emitted when an enemy wave starts
signal wave_started(wave_config: Dictionary)

# Emitted when followers reach a multiple of 5 — triggers shrine spawn
signal shrine_unlocked()

# Emitted when a shrine construction site is placed at a world position
signal shrine_site_placed(site_position: Vector2)

# Emitted when an NPC is assigned a civilization role
signal npc_role_assigned(npc: Node, role: String)
