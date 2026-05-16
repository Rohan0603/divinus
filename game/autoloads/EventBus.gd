## EventBus — global message broker.
## All game systems emit here; listeners connect here.
## Never store state: this is pure signal relay.
extends Node

signal boon_cast(boon_type: String)       # a divine power was used
signal npc_converted(npc: Node)           # NPC entered Follower state
signal shrine_built(position: Vector2)    # player placed a shrine
signal enemy_killed(enemy: Node)          # enemy was defeated
signal day_changed(day: int)              # DayClock ticked over
signal wave_started(wave_num: int)        # enemy wave began
