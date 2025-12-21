# Spector Art

Spector its like colors. Art is subjective.

# Mechanics
- [__Keys and Locks__](materials/scripts/key_lock/README.md) - A key opens a corresponding lock, enabling interaction with "levers" across different levels or scenes.

- [__Combat and Collision Boxes__](materials/scripts/boxes/README.md) - Hitbox, hurtbox, parrybox, pushbox, similar to those used in fighting games.

# Systems
- [__Functions Library__](autoload/functions.gd) - Global utility functions for mathematics, pause management, screen effects, and geometry operations.

- [__Phantom Camera__](addons/phantom_camera) - Advanced camera system with 2D/3D support, multiple camera types, noise effects, and smooth transitions.

- [__Save System__](materials/scripts/saver/README.md) - Comprehensive game state persistence with automatic node tracking, manual checkpoints, and file-based save/load operations.

- [__Buffer System__](addons/buff_er/README.md) - Input buffering and action timing management for responsive player controls (coyote jump, input buffering, etc.).

- [__Dynamic Expression__](materials/scripts/dynamic_expression/README.md) - Flexible expression evaluation system for mathematical calculations, logical conditions, and property assignments with NodePath resolution.

- [__Input Monitor__](autoload/input_monitor/input_mointor.gd) - Device-aware input display system that automatically detects input devices (keyboard/gamepad) and provides localized button names and images for different platforms (xBox, PlayStation, Nintendo, PC).

# Objects

- [__Multichecker__](materials/scripts/multichecker/README.md) - Interactive multi-choice menu system with conditional options, integrated with key-lock mechanics and dynamic expressions for complex game interactions.

- [__DynamicExpression__](materials/scripts/dynamic_expression/dynamic_expression.gd) - Flexible expression evaluation system for mathematical calculations, logical conditions, and property assignments with NodePath resolution.


<details>
<summary> Key&Lock </summary>

- [__KLKey__](materials/scripts/key_lock/key.gd) - Interactive key component that can be activated/deactivated with timer support, blocking conditions, and dynamic expressions for complex game logic.

- [__KLLock__](materials/scripts/key_lock/lock.gd) - Logical lock that evaluates boolean expressions using key states to determine activation conditions.

</details>

<details>
<summary> Combat and Collision Boxes </summary>

- [__HitBox__](materials/scripts/boxes/hit_box.gd) - Offensive collision area for dealing damage with configurable detection modes, timers, and single/multi-hit behavior.

- [__HurtBox__](materials/scripts/boxes/hurt_box.gd) - Damageable collision area with health management, invincibility frames, and raycast verification for accurate damage detection.

- [__ParryBox__](materials/scripts/boxes/parry_box.gd) - Defensive collision area for intercepting and parrying HitBox attacks with knockback calculations.

- [__PullBox__](materials/scripts/boxes/pull_box.gd) - Attraction area that pulls physics bodies toward its center with configurable speed and detection modes.

</details>