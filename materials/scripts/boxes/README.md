# Boxes System

Collection of collision-based interaction components for game entities.

## Components

### HurtBox2D
Health management system that receives damage from HitBox2D components in 2D space.

**Key Features:**
- Health points with maximum health limit in 2D environments
- Invincibility frames with automatic timer management
- Damage calculation with delta time scaling
- 2D raycast collision detection option for line-of-sight verification
- Exception handling for specific HitBox2D instances
- Single detection mode for one-time damage

**Properties:**
- `flags`: 2D physics collision mask for raycast detection
- `exceptions`: Array of HitBox2D objects to ignore
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
- Attach to 2D entities that can take damage
- Connect health signals for UI/health bar updates in 2D games
- Use exceptions to ignore friendly fire in 2D space
- Configure raycast detection to prevent damage through 2D obstacles

---

### ParryBox2D
Defensive component that parries incoming attacks and creates 2D knockback.

**Features:**
- Automatic parry detection for HitBox2D collisions in 2D space
- 2D knockback direction calculation based on collision position
- Signal emission for parry events in two dimensions

**Signals:**
- `self_knockback(direction:Vector2)` - 2D knockback direction for the parrying entity
- `parried(area:HitBox2D)` - Parry event with the parried HitBox2D

**Usage:**
- Attach to 2D entities that can parry attacks
- Connect signals to implement parry mechanics (animations, sound, etc.) in 2D
- Use 2D knockback signal to repel the parrying entity in space

---

### HitBox2D
Base attack component that deals damage to HurtBox2D components in 2D space.

**Properties:**
- `damage`: Damage value per second/frame in 2D collisions
- `deletion_timer`: Auto-destruction timer (0 = permanent)
- `detect_by_ray`: Use 2D raycast for line-of-sight validation
- `single_detect`: One-time detection per HurtBox2D
- `stepped`: Whether the HitBox2D has been used (for single_detect mode)

**Usage:**
- Attach to 2D attack projectiles, melee weapons, or hazard areas
- Configure damage values and detection modes for 2D combat
- Use deletion_timer for temporary attack effects in 2D space
- Combine with 2D raycast detection to prevent damage through walls

---

### CustomDetectionBox2D
Interactive detection area that executes dynamic expressions when bodies enter or exit.

**Key Features:**
- Executes configurable dynamic expressions on 2D body collision events
- Supports multiple callbacks for complex 2D trigger behaviors
- Integrates with DynamicExpression system for flexible event handling
- Automatic NodePath resolution for expression variables in 2D scenes

**Properties:**
- `body_entered_callbacks`: Array of expressions executed when bodies enter
- `body_exited_callbacks`: Array of expressions executed when bodies exit

**Usage:**
- Attach to create interactive zones in 2D space without writing code
- Configure expressions for sounds, animations, or state changes in 2D
- Use with DynamicExpression for complex event logic in 2D environments
- Combine with other 2D boxes for layered interactions

---

### PullBox2D
Physics-based pulling/pushing system for moving 2D entities.

**Key Features:**
- Pulls 2D entities toward the PullBox2D center in two dimensions
- Configurable pull speed and 2D direction
- Support for CharacterBody2D and RigidBody2D in 2D space
- Single detection mode for one-time effects in 2D
- Exception handling for specific 2D entities

**Properties:**
- `enabled`: Enable/disable pulling effect in 2D
- `speed`: Pull velocity magnitude in 2D units per second
- `single_detect`: One-time effect per 2D entity
- `exceptions`: Array of 2D entities to ignore

**Usage:**
- Attach to magnets, vacuum effects, or 2D conveyor belts
- Configure pull direction via 2D node rotation
- Use exceptions to prevent pulling specific 2D entities
- Combine with single_detect for trigger-style effects in 2D

## System Integration

All 2D components work together through Godot's Area2D collision system:
- HitBox2D components deal damage to HurtBox2D components
- ParryBox2D can intercept HitBox2D collisions before they reach HurtBox2D
- PullBox2D affects 2D physics bodies independently
- CustomDetectionBox2D provides event-driven callbacks for interactive 2D zones
- Components can be layered and combined for complex 2D interactions

## Common Patterns

**Basic Combat:**
```
Entity
├── HurtBox2D (health management)
├── ParryBox2D (defensive mechanics)
└── HitBox2D (attack component)
```

**Magnetic Field:**
```
MagneticObject
└── PullBox2D (pulls nearby 2D physics bodies)
```

**Projectile:**
```
Projectile
├── HitBox2D (damage dealing)
└── PullBox2D (homing behavior)
```

---

## 3D Components

The Boxes System also provides 3D equivalents of all components, designed specifically for three-dimensional game environments. All 3D components extend `Area3D` and use appropriate 3D physics and vector mathematics.

### HurtBox3D
Damageable collision area that receives damage from HitBox3D components in 3D space.

**Key Features:**
- Health points with maximum health limit in 3D environments
- Invincibility frames with automatic timer management
- Damage calculation with delta time scaling
- 3D raycast collision detection option for line-of-sight verification
- Exception handling for specific HitBox3D instances

**Properties:**
- `flags`: 3D physics collision mask for raycast detection
- `exceptions`: Array of HitBox3D objects to ignore
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
- Attach to 3D entities that can take damage
- Connect health signals for UI/health bar updates in 3D games
- Use exceptions to ignore friendly fire in 3D space
- Configure raycast detection to prevent damage through 3D obstacles

---

### ParryBox3D
Defensive component that parries incoming attacks and creates 3D knockback.

**Features:**
- Automatic parry detection for HitBox3D collisions in 3D space
- 3D knockback direction calculation based on collision position
- Signal emission for parry events in three dimensions

**Signals:**
- `self_knockback(direction:Vector3)` - 3D knockback direction for the parrying entity
- `parried(area:HitBox3D)` - Parry event with the parried HitBox3D

**Usage:**
- Attach to 3D entities that can parry attacks
- Connect signals to implement parry mechanics (animations, sound, etc.) in 3D
- Use 3D knockback signal to repel the parrying entity in space

---

### HitBox3D
Base attack component that deals damage to HurtBox3D components in 3D space.

**Properties:**
- `damage`: Damage value per second/frame in 3D collisions
- `deletion_timer`: Auto-destruction timer (0 = permanent)
- `detect_by_ray`: Use 3D raycast for line-of-sight validation
- `single_detect`: One-time detection per HurtBox3D
- `stepped`: Whether the HitBox3D has been used (for single_detect mode)

**Usage:**
- Attach to 3D attack projectiles, melee weapons, or hazard areas
- Configure damage values and detection modes for 3D combat
- Use deletion_timer for temporary attack effects in 3D space
- Combine with 3D raycast detection to prevent damage through walls

---

### CustomDetectionBox2D3D
Interactive detection area that executes dynamic expressions when 3D bodies enter or exit.

**Key Features:**
- Executes configurable dynamic expressions on 3D body collision events
- Supports multiple callbacks for complex 3D trigger behaviors
- Integrates with DynamicExpression system for flexible event handling
- Automatic NodePath resolution for expression variables in 3D scenes

**Properties:**
- `body_entered_callbacks`: Array of expressions executed when 3D bodies enter
- `body_exited_callbacks`: Array of expressions executed when 3D bodies exit

**Usage:**
- Attach to create interactive zones in 3D space without writing code
- Configure expressions for sounds, animations, or state changes in 3D
- Use with DynamicExpression for complex event logic in 3D environments
- Combine with other 3D boxes for layered interactions

---

### PullBox3D
Physics-based pulling/pushing system for moving 3D entities.

**Key Features:**
- Pulls 3D entities toward the PullBox3D center in three dimensions
- Configurable pull speed and 3D direction
- Support for CharacterBody3D and RigidBody3D in 3D space
- Single detection mode for one-time effects in 3D
- Exception handling for specific 3D entities

**Properties:**
- `enabled`: Enable/disable pulling effect in 3D
- `speed`: Pull velocity magnitude in 3D units per second
- `single_detect`: One-time effect per 3D entity
- `exceptions`: Array of 3D entities to ignore

**Usage:**
- Attach to magnets, vacuum effects, or 3D conveyor belts
- Configure pull direction via 3D node rotation
- Use exceptions to prevent pulling specific 3D entities
- Combine with single_detect for trigger-style effects in 3D