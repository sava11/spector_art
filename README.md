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

- [__Input Visualizer__](autoload/input_visualizer/input_visualizer.gd) - Device-aware input display system that automatically detects input devices (keyboard/gamepad) and provides localized button names and images for different platforms (xBox, PlayStation, Nintendo, PC).

- [__Waypoint System__](materials/scripts/waypoint/README.md) - Screen-space visual navigation indicators that show direction to their own positions in 2D and 3D space, always visible on screen with icon-based styling.


# Objects

- [__DynamicExpression__](materials/scripts/dynamic_expression/dynamic_expression.gd) - Flexible expression evaluation system for mathematical calculations, logical conditions, and property assignments with NodePath resolution.

- [__Pawn2D__](materials/scenes/pawn/2d/pawn.gd) - 2D pawn character with physics-based movement and action system integration.

- [__Pawn3D__](materials/scenes/pawn/3d/pawn.gd) - 3D pawn character with physics-based movement and action system integration.

- [__Action__](materials/scenes/pawn/action.gd) - Abstract base class for pawn actions with conditional execution and dynamic expressions.


<details>
<summary> Save Load System </summary>

- [__SaveSystemBase__](materials/scripts/saver/saver_base.gd) - Base class for save system implementations providing core file I/O functionality and data serialization.

- [__SaveCheckpoint__](materials/scripts/saver/checkpoint.gd) - Checkpoint system for saving specific game states with predefined node configurations and automatic save management.

- [__SaveLoader__](materials/scripts/saver/node_data_registrator.gd) - Node registration system for automatic save/load tracking with property monitoring and state persistence.

</details>

<details>
<summary> Controllers </summary>

- [__BaseController__](materials/scripts/puppet_input/controller_base.gd) - Base class for input controllers providing common functionality and state management for player controls.

- [__PlayerController__](materials/scripts/puppet_input/player_controller.gd) - Player input controller implementing movement, actions, and state management with buffer systems.

</details>

<details>
<summary> Multichecker </summary>

- [__Multichecker__](materials/scripts/multichecker/multichecker.gd) - Core menu controller managing UI generation, Key-Lock integration, and user interaction processing.

- [__MulticheckerUI__](materials/scripts/multichecker/multichecker_ui.gd) - User interface handler for menu display, input device detection, and focus management.

- [__MulticheckerItem__](materials/scripts/multichecker/item.gd) - Configuration resource defining individual menu options with conditional behavior and action bindings.

</details>

<details>
<summary> Pawn Actions </summary>

- [__Action__](materials/scenes/pawn/action.gd) - Abstract base class for pawn actions with conditional execution and dynamic expressions.


<details>
<summary> 2D </summary>

- [__AttackAction2D__](materials/scenes/pawn/2d/actions/attack_action.gd) - 2D attack action system for pawn characters with sequential combo chains, configurable HitBox2D components, and input buffering.

- [__MoveAction2D__](materials/scenes/pawn/2d/actions/move_action.gd) - 2D movement action handling horizontal movement with acceleration and deceleration.

- [__DashAction2D__](materials/scenes/pawn/2d/actions/dash_action.gd) - 2D dash action providing quick directional movement bursts.

</details>

<details>
<summary> 3D </summary>

- [__AttackAction3D__](materials/scenes/pawn/3d/actions/attack_action.gd) - 3D attack action system for pawn characters with sequential combo chains and HitBox3D components.

- [__MoveAction3D__](materials/scenes/pawn/3d/actions/move_action.gd) - 3D movement action handling horizontal movement with acceleration and deceleration.

- [__DashAction3D__](materials/scenes/pawn/3d/actions/dash_action.gd) - 3D dash action providing quick directional movement bursts.

- [__JumpAction3D__](materials/scenes/pawn/3d/actions/jump_action.gd) - 3D jump action handling vertical movement and jump physics.

- [__GravityAction3D__](materials/scenes/pawn/3d/actions/gravity_action.gd) - 3D gravity action applying downward acceleration to pawns.

</details>

</details>

<details>
<summary> Keys and Locks </summary>

- [__KLKey__](materials/scripts/key_lock/key.gd) - Interactive key component that can be activated/deactivated with timer support, blocking conditions, and dynamic expressions for complex game logic.

- [__KLLock__](materials/scripts/key_lock/lock.gd) - Logical lock that evaluates boolean expressions using key states to determine activation conditions.

</details>

<details>
<summary> Waypoint System </summary>

- [__WayPoint2D__](materials/scripts/waypoint/waypoint_2d.gd) - Screen-space visual direction indicator for 2D navigation that shows direction to its own world position, always visible on screen with icon-based visualization.

- [__WayPoint3D__](materials/scripts/waypoint/waypoint_3d.gd) - Screen-space visual direction indicator for 3D navigation that shows direction to its own world position using camera projection, always visible on screen with icon-based visualization.

</details>

<details>
<summary> Combat and Collision Boxes </summary>

<details>
<summary> 2D </summary>

- [__CustomDetectionBox2D__](materials/scripts/boxes/2d/custom_detection_box.gd) - Interactive 2D detection area that executes dynamic expressions on body enter/exit events for creating triggers and event systems.

- [__HitBox2D__](materials/scripts/boxes/2d/hit_box.gd) - Offensive 2D collision area for dealing damage with configurable detection modes, timers, and single/multi-hit behavior.

- [__HurtBox2D__](materials/scripts/boxes/2d/hurt_box.gd) - Damageable 2D collision area with health management, invincibility frames, and raycast verification for accurate damage detection.

- [__ParryBox2D__](materials/scripts/boxes/2d/parry_box.gd) - Defensive 2D collision area for intercepting and parrying HitBox2D attacks with knockback calculations.

- [__PullBox2D__](materials/scripts/boxes/2d/pull_box.gd) - 2D attraction area that pulls physics bodies toward its center with configurable speed and detection modes.

</details>

<details>
<summary> 3D </summary>

- [__CustomDetectionBox3D__](materials/scripts/boxes/3d/custom_detection_box.gd) - Interactive 3D detection area that executes dynamic expressions on body enter/exit events for creating triggers and event systems.

- [__HitBox3D__](materials/scripts/boxes/3d/hit_box.gd) - Offensive 3D collision area for dealing damage with configurable detection modes, timers, and single/multi-hit behavior.

- [__HurtBox3D__](materials/scripts/boxes/3d/hurt_box.gd) - Damageable 3D collision area with health management, invincibility frames, and raycast verification for accurate damage detection.

- [__ParryBox3D__](materials/scripts/boxes/3d/parry_box.gd) - Defensive 3D collision area for intercepting and parrying HitBox3D attacks with knockback calculations.

- [__PullBox3D__](materials/scripts/boxes/3d/pull_box.gd) - 3D attraction area that pulls physics bodies toward its center with configurable speed and detection modes.

</details>

</details>