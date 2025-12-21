# Save System

Comprehensive game state persistence system for managing save/load functionality across different game entities and scenes.

## Overview

The save system provides a hierarchical architecture with automatic and manual save capabilities. It consists of a global save manager (SLD) that coordinates data persistence, with specialized components for different saving patterns.

## Core Components

### SaveSystemBase
Base class providing core file I/O and serialization functionality.

**Key Features:**
- File system operations with automatic backup creation
- Data serialization and validation
- Directory management for save files
- Error handling for file operations

**Constants:**
- `SAVE_DIR`: Directory path for save files ("saves/")
- `EXT`: File extension for save files (".dat")

**Methods:**
- `_save_to_file(save_file_name)`: Save data with backup
- `_load_from_file(save_file_name)`: Load data with validation
- `_remove_save_file(save_file_name)`: Delete save file
- `get_and_clear_data(save_file_name)`: Load data without affecting internal state

**Usage:**
- Extend this class for custom save implementations
- Handles all low-level file operations
- Provides error codes for operation status

---

### SLD (SaveLoader)
Main save/load system extending SaveSystemBase for node-based game state management.

**Key Features:**
- Node registration system for selective saving
- Automatic cleanup when nodes are removed
- Signal-based save/load event notifications
- Property-level save granularity

**Properties:**
- `save_file`: Name of the save file (default: "save")
- `registered_nodes`: Dictionary of tracked nodes and their properties

**Signals:**
- `saving_started` - Save operation begins
- `saving_finished` - Save operation completes
- `loading_started` - Load operation begins
- `loading_finished` - Load operation completes

**Usage:**
```gdscript
# Register nodes for saving
SLD.register_node(player, ["position", "health", "inventory"])
SLD.register_node(game_state, ["level", "score", "achievements"])

# Manual save/load
SLD.make_save()  # Save current state
SLD.load_save()  # Load saved state
```

---

### SaveLoader (Node Data Registrator)
Automatic save component that attaches to individual nodes for real-time property tracking.

**Key Features:**
- Automatic change detection and saving
- Configurable update intervals
- Memory-efficient byte-level change tracking
- Signal-based notifications for save events

**Properties:**
- `properties`: Array of property names to track
- `auto_update`: Enable automatic periodic saving
- `update_interval`: Time between change checks (default: 0.2s)

**Signals:**
- `loaded` - Data loaded into parent node
- `changed_and_pushed(path, changed_keys)` - Properties updated in save system

**Usage:**
- Attach as child node to objects needing saving
- Configure properties array for tracked values
- Use `auto_update` for continuous saving
- Call `force_push()` for immediate saves

---

### SaveCheckpoint
Predefined save point system for creating specific game state snapshots.

**Key Features:**
- Static data definition for save points
- Node path-based property assignment
- Enable/disable functionality
- Integration with global save system

**Properties:**
- `data`: Dictionary defining node states `{NodePath: {property: value}}`
- `enabled`: Whether checkpoint can be used

**Signals:**
- `on_saved` - Checkpoint save completed

**Usage:**
```gdscript
# Define checkpoint data in editor
data = {
	"../Player": {"position": Vector2(100, 200), "health": 100},
	"../GameState": {"level": 3, "score": 1500}
}

# Save checkpoint
checkpoint.save()
```

## System Architecture

```
SLD (Global Autoload)
├── SaveSystemBase (Base functionality)
├── Node Registration System
├── File I/O Operations
└── Save/Load Coordination

Individual Nodes
├── SaveLoader (Auto-tracking component)
│   ├── Property monitoring
│   ├── Change detection
│   └── Automatic saving
└── SaveCheckpoint (Manual save points)
	├── Static data definition
	└── One-time save operations
```

## Data Flow

1. **Registration**: Nodes register with SLD specifying properties to save
2. **Tracking**: SaveLoader components monitor property changes automatically
3. **Collection**: SLD collects current values from registered nodes
4. **Serialization**: Data converted to binary format with backup creation
5. **Persistence**: Saved to disk in structured format
6. **Loading**: Data restored and applied to nodes on load

## Common Patterns

**Player Character Persistence:**
```
PlayerCharacter
├── SaveLoader
│   ├── properties: ["position", "health", "inventory", "stats"]
│   ├── auto_update: true
│   └── update_interval: 0.5
└── Custom Components
```

**Game State Management:**
```
GameManager (Autoload)
├── SaveLoader
│   ├── properties: ["current_level", "player_score", "achievements"]
│   └── auto_update: true
└── Level Data
```

**Checkpoint System:**
```
Level
├── SaveCheckpoint (Start)
│   └── data: {initial player state}
├── SaveCheckpoint (Mid-level)
│   └── data: {progress state}
└── SaveCheckpoint (Boss)
	└── data: {pre-boss state}
```

## Integration Guidelines

- **Node Registration**: Always register nodes before saving operations
- **Property Types**: System handles most Godot types (Vector2, Dictionary, etc.)
- **Scene Changes**: Save before scene transitions, load after
- **Performance**: Use appropriate update intervals for auto-saving
- **Error Handling**: Check return codes from file operations
- **Backup Safety**: System automatically creates backups before overwriting

## Best Practices

1. **Selective Saving**: Only save necessary properties to reduce file size
2. **Auto vs Manual**: Use auto-update for critical data, manual for checkpoints
3. **Validation**: Always validate loaded data before applying to nodes
4. **Versioning**: Consider save file versioning for game updates
5. **Testing**: Test save/load cycles thoroughly across different scenarios</contents>
