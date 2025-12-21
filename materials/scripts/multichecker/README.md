# Multichecker System

Interactive multi-choice menu system with conditional options, integrated with key-lock mechanics and dynamic expressions for complex game interactions.

## Overview

Multichecker provides a flexible menu system where players can make choices from multiple options, with each option potentially being locked or unlocked based on game state. The system integrates deeply with the Key-Lock system for conditional access and Dynamic Expression system for complex logic execution.

## Core Components

### Multichecker
Main menu controller that manages the UI, user input, and option selection logic.

**Key Features:**
- Dynamic menu generation from MulticheckerItem resources
- Integration with Key-Lock system for conditional option access
- Support for toggle and single-action buttons
- Automatic save/load of menu state and selections
- Pause management during menu interaction
- Focus management for keyboard/controller navigation

**Properties:**
- `enabled`: Master enable/disable switch
- `blocked`: External blocking state from Key-Lock system
- `showed`: Menu visibility state
- `time_stop`: Pause game time when menu is shown
- `close_after_choice`: Auto-hide menu after single selection
- `items`: Array of MulticheckerItem configurations
- `current_id`: Currently selected option index
- `prompt_action`: Input action for menu confirmation
- `prompt_desc`: Help text translation key

**States:**
- `is_activated()`: Returns true if menu is active and not blocked

**Signals:**
- `current_id_changed(result:bool, id:int)` - Selection changed

**UI Components:**
- `prompt`: Help prompt panel showing input hints
- `collection`: Main menu panel with selectable options
- `button_container`: Container for dynamically created buttons

**Usage:**
- Attach to scene as a Node2D
- Configure items array with MulticheckerItem resources
- Connect to current_id_changed signal for handling selections
- Use set_showed(true) to display the menu

---

### MulticheckerItem
Configuration resource defining individual menu options and their behavior.

**Key Features:**
- Conditional visibility based on game state
- Key-Lock integration for access control
- Dynamic expression execution on activation/deactivation
- Toggle mode for persistent state changes
- Auto-reset functionality with timers

**Basic Properties:**
- `uid`: Unique identifier for key-lock system
- `name`: Display text (translation key)
- `visible`: UI visibility control
- `toggled`: Toggle button behavior
- `timer`: Auto-reset duration in seconds

**Lock Configuration:**
- `lock_expression`: Logical expression defining access conditions
- `lock_keys`: Array of key UIDs referenced in lock expression

**Reset Configuration:**
- `reset_when_blocked`: Reset state when blocked
- `reset_value`: Value to reset to when blocked

**Action Configuration:**
- `callables_on_pressed`: Dynamic expressions executed on activation
- `callables_on_released`: Dynamic expressions executed on deactivation (toggle mode only)

**Usage:**
- Create as a resource in the editor
- Configure lock conditions using key UIDs and expressions
- Add dynamic expressions for custom logic on selection
- Use toggle mode for persistent menu states

## System Architecture

```
Multichecker (Node2D)
├── SaveLoader (current_id persistence)
├── KLLock (master blocking)
├── keys_root/
│   └── KLKey instances (per item)
├── prompt (UI help panel)
├── collection (main menu panel)
│   └── button_container
│       └── Button instances (dynamically created)
└── UI layout and focus management
```

## Integration Patterns

**Conditional Dialogue Choices:**
```
Multichecker
├── MulticheckerItem (unlocked choice)
│   ├── lock_expression: "!blocked_key"
│   └── callables_on_pressed: [dialogue_advance]
└── MulticheckerItem (locked choice)
    ├── lock_expression: "has_item_key"
    └── callables_on_pressed: [special_dialogue]
```

**Ability Selection Menu:**
```
Multichecker
├── MulticheckerItem (Fire Magic)
│   ├── toggled: true
│   ├── lock_expression: "fire_unlocked"
│   └── callables_on_pressed: [equip_fire_magic]
├── MulticheckerItem (Ice Magic)
│   ├── toggled: true
│   ├── lock_expression: "ice_unlocked"
│   └── callables_on_pressed: [equip_ice_magic]
└── MulticheckerItem (Back)
    └── callables_on_pressed: [close_menu]
```

## Expression Syntax

Lock expressions use the same syntax as KLLock:
- Numbers reference keys by array index (0, 1, 2...)
- `&` or `&&` for AND operations
- `|` or `||` for OR operations
- `!` for NOT operations
- Parentheses for grouping: `(0 | 1) & !2`

## Data Flow

1. **Initialization**: Multichecker creates UI elements and KLKey instances for each item
2. **Lock Evaluation**: KLLock evaluates expressions based on key states
3. **UI Update**: Buttons are enabled/disabled based on lock states
4. **Input Handling**: User selection triggers KLKey activation
5. **Action Execution**: Dynamic expressions execute custom logic
6. **State Persistence**: SaveLoader automatically saves menu state

## Best Practices

1. **UID Management**: Use consistent UIDs across scenes for persistent state
2. **Expression Complexity**: Keep lock expressions readable and well-documented
3. **Performance**: Limit number of items for better UI performance
4. **Accessibility**: Provide clear visual feedback for locked/unlocked states
5. **Testing**: Test all lock conditions and edge cases thoroughly

