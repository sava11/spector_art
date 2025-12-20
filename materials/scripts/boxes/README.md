# Boxes System

Collection of collision-based interaction components for game entities.

## Components

### HurtBox
Health management system that receives damage from HitBox components.

**Key Features:**
- Health points with maximum health limit
- Invincibility frames with automatic timer
- Damage calculation with delta time
- Raycast collision detection option
- Exception handling for specific HitBox instances
- Single detection mode for one-time damage

**Properties:**
- `flags`: Physics collision mask for raycast detection
- `exceptions`: Array of HitBox objects to ignore
- `tspeed`: Invincibility frame duration
- `max_health`: Maximum health value

**States:**
- `invincible`: Current invincibility state
- `health`: Current health value
- `alive`: Whether entity is alive (health > 0)

**Signals:**
- `invi_started` - Invincibility period began
- `invi_ended` - Invincibility period ended
- `alive(alive:bool)` - Alive state changed
- `health_changed(value:float, delta:float)` - Health value changed
- `max_health_changed(value:float, delta:float)` - Max health changed

**Usage:**
- Attach to entities that can take damage
- Connect health signals for UI/health bar updates
- Use exceptions to ignore friendly fire
- Configure raycast detection for line-of-sight damage

---

### ParryBox
Defensive component that parries incoming attacks and creates knockback.

**Features:**
- Automatic parry detection for HitBox collisions
- Knockback direction calculation based on collision position
- Signal emission for parry events

**Signals:**
- `self_knockback(direction:Vector2)` - Knockback direction for the parrying entity
- `parried(area:HitBox)` - Parry event with the parried HitBox

**Usage:**
- Attach to entities that can parry attacks
- Connect signals to implement parry mechanics (animations, sound, etc.)
- Use knockback signal to repel the parrying entity

---

### HitBox
Base attack component that deals damage to HurtBox components.

**Properties:**
- `damage`: Damage value per second/frame
- `deletion_timer`: Auto-destruction timer (0 = permanent)
- `detect_by_ray`: Use raycast for line-of-sight validation
- `single_detect`: One-time detection per HurtBox
- `stepped`: Whether the HitBox has been used (for single_detect mode)

**Usage:**
- Attach to attack projectiles, melee weapons, or hazard areas
- Configure damage values and detection modes
- Use deletion_timer for temporary attack effects
- Combine with raycast detection to prevent damage through walls

---

### PullBox
Physics-based pulling/pushing system for moving entities.

**Key Features:**
- Pulls entities toward the PullBox center
- Configurable pull speed and direction
- Support for CharacterBody2D and RigidBody2D
- Single detection mode for one-time effects
- Exception handling for specific entities

**Properties:**
- `enabled`: Enable/disable pulling effect
- `speed`: Pull velocity magnitude
- `single_detect`: One-time effect per entity
- `exceptions`: Array of entities to ignore

**Usage:**
- Attach to magnets, vacuum effects, or conveyor belts
- Configure pull direction via node rotation
- Use exceptions to prevent pulling specific entities
- Combine with single_detect for trigger-style effects

## System Integration

All components work together through Godot's Area2D collision system:
- HitBox components deal damage to HurtBox components
- ParryBox can intercept HitBox collisions before they reach HurtBox
- PullBox affects physics bodies independently
- Components can be layered and combined for complex interactions

## Common Patterns

**Basic Combat:**
```
Entity
├── HurtBox (health management)
├── ParryBox (defensive mechanics)
└── HitBox (attack component)
```

**Magnetic Field:**
```
MagneticObject
└── PullBox (pulls nearby physics bodies)
```

**Projectile:**
```
Projectile
├── HitBox (damage dealing)
└── PullBox (homing behavior)
```
