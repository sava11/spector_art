# Waypoint System

Screen-space visual navigation system for indicating directions to targets in both 2D and 3D space.

## Overview

The Waypoint System provides screen-space visual indicators that point toward target nodes. Waypoints are always visible on screen - either positioned above targets (when on screen) or on the screen edge pointing toward the target direction (when off screen). The system uses icon-based visualization with automatic distance-based visibility management.

## Components

### Waypoint2D
Screen-space visual direction indicator for 2D navigation that shows direction to its own position.

**Key Features:**
- Always visible on screen (screen-space rendering)
- Positions at waypoint location when on screen, on screen edge when off screen
- Icon rotates to point toward waypoint when off screen
- Distance-based visibility and fade effects
- Configurable colors, sizes, and offsets
- Improved edge positioning with proper aspect ratio handling
- Position-based: waypoint shows direction to itself

**Properties:**
- `icon_color`: Color of the waypoint icon
- `size`: Size multiplier for icon
- `max_distance`: Maximum visibility range (0 = unlimited)
- `fade_distance`: Distance for fade-in effect
- `screen_offset`: Offset when waypoint is on screen
- `icon_texture`: Custom texture for the icon
- `screen_margin`: Margin from screen edge for off-screen waypoints

**Usage:**
```gdscript
var waypoint = Waypoint2D.new()
waypoint.icon_color = Color.YELLOW
waypoint.icon_texture = preload("res://objective_icon.png")
waypoint.position = Vector2(100, 200)  # World position of the waypoint
add_child(waypoint)
```

---

### Waypoint3D
Screen-space visual direction indicator for 3D navigation that shows direction to its own position.

**Key Features:**
- Always visible on screen using 3D-to-2D projection
- Positions at waypoint location when on screen, on screen edge when off screen
- Icon rotates to point toward waypoint when off screen
- Distance-based visibility and fade effects
- Configurable colors, sizes, and offsets
- Improved 3D visibility detection (checks if object is in front of camera)
- Enhanced edge positioning with proper aspect ratio handling
- Screen-space rendering for consistent appearance

**Properties:**
- `icon_color`: Color of the waypoint icon
- `size`: Size multiplier for icon
- `max_distance`: Maximum visibility range (0 = unlimited)
- `fade_distance`: Distance for fade-in effect
- `screen_offset`: Offset when waypoint is on screen
- `icon_texture`: Custom texture for the icon
- `screen_margin`: Margin from screen edge for off-screen waypoints

**Usage:**
```gdscript
var waypoint = Waypoint3D.new()
waypoint.icon_color = Color.CYAN
waypoint.icon_texture = preload("res://objective_3d_icon.png")
waypoint.position = Vector3(10, 5, 20)  # World position of the waypoint
add_child(waypoint)
```

## Visual Style

The waypoint system uses **icon-based visualization** with screen-space rendering:

- **On-screen targets**: Icon appears directly above the target with configurable vertical offset
- **Off-screen targets**: Icon appears on the screen edge, rotated to point toward the target direction
- **Custom textures**: Support for any Sprite texture for branded or themed indicators
- **Rotation**: Icons automatically rotate when off-screen to indicate direction
- **Consistent sizing**: Icons maintain consistent screen size regardless of target distance

## Common Usage Patterns

### Objective Tracking
```
Scene
├── Player
├── Waypoint2D (objective marker)
│   ├── position = Vector2(500, 300)
│   ├── icon_texture = treasure_icon.png
│   └── screen_offset = Vector2(0, -30)
└── Treasure (decorative object)
```

### Multi-Target Navigation
```
Scene
├── Player
├── Waypoints (Node container)
│   ├── Waypoint2D (Quest Location)
│   │   ├── position = Vector2(200, 150)
│   │   └── icon_color = Color.YELLOW
│   ├── Waypoint2D (Shop Location)
│   │   ├── position = Vector2(800, 400)
│   │   └── icon_color = Color.GREEN
│   └── Waypoint2D (Exit Location)
│       ├── position = Vector2(1000, 600)
│       └── icon_color = Color.RED
└── Scene Decorations
```

### 3D World Navigation
```
3D_Scene
├── Player (with Camera3D)
├── Waypoint3D (objective marker)
│   ├── position = Vector3(25, 10, 50)
│   ├── icon_texture = chest_icon.png
│   └── max_distance = 1000.0
└── TreasureChest (decorative object)
```

### Distance-Based UI
```
UI_Canvas
├── Waypoint2D
│   ├── max_distance = 500.0
│   ├── fade_distance = 100.0
│   └── icon_texture = objective_icon.png
└── DistanceLabel (connected to distance_changed signal)
```

## Integration with Other Systems

### With Key-Lock System
Waypoints can be shown/hidden based on key possession:
```gdscript
func _on_key_collected(key_name: String):
    if key_name == "treasure_map":
        treasure_waypoint.visible = true
```

### With Dynamic Expressions
Waypoint properties can be controlled by expressions:
```gdscript
# waypoint.icon_color = Color(1, 0, 0) if global_position.distance_to(player.position) > 100 else Color(0, 1, 0)
waypoint.set("icon_color", expression.execute(self))
```

### With Save System
Waypoint states can be saved and restored:
```gdscript
func save_waypoint_state():
    return {
        "position": waypoint.position,
        "icon_color": waypoint.icon_color,
        "max_distance": waypoint.max_distance,
        "visible": waypoint.visible
    }
```

## Performance Considerations

- Waypoints update every frame with screen-space calculations
- Use `max_distance` to limit visibility range and reduce calculations
- For many waypoints, consider object pooling or distance-based culling
- Screen-space rendering is optimized for UI performance
- Consider disabling waypoints for completed objectives

### Performance Optimizations
- Reduced unnecessary calculations when waypoints are beyond maximum distance
- Optimized camera reference updates to avoid redundant searches
- Efficient screen space transformations with proper bounds checking

## Tips

- Always test with different screen resolutions and aspect ratios
- Use high-contrast icons for better visibility
- Combine with animation (tweening position/size) for attention-grabbing effects
- Use different colors to distinguish objective types
- Connect to `on_screen_changed` signal for audio/visual feedback
- For 3D scenes, ensure Camera3D is properly set up for projection calculations
- Use `screen_margin` to prevent waypoints from being cut off by UI elements
- Test with various camera angles and distances to ensure consistent waypoint behavior
