# Multichecker System

Advanced interactive multi-choice menu system with conditional options and deep game state integration.

## Overview

The Multichecker system provides a sophisticated menu framework where players can select from multiple options, with each choice potentially locked or unlocked based on complex game state conditions. The system seamlessly integrates with the Key-Lock mechanics for conditional access control and the Dynamic Expression system for executing sophisticated game logic upon selection.

**Key Capabilities:**
- Dynamic menu generation from configurable item resources
- Real-time conditional option availability through Key-Lock expressions
- Support for both persistent toggle switches and single-action buttons
- Automatic state persistence across game sessions
- Integrated pause management and time control
- Keyboard and controller navigation with focus management
- Device-aware input visualization (keyboard/gamepad icons)
- Localization support for all menu text

## Core Components

### Multichecker (Node)
Primary menu controller managing user interaction, and game state integration.

**Core Responsibilities:**
- Dynamic UI construction from MulticheckerItem configurations
- Key-Lock system integration for conditional option availability
- Real-time menu state synchronization with game world
- Input handling and device-adaptive visualization
- Pause state management during menu interaction
- Focus and navigation control for accessibility

**Configuration Properties:**
- `enabled`: Master on/off switch controlling overall availability
- `blocked`: External blocking state (connected to KLLock for game state control)
- `time_stop`: Whether to pause game time when menu is active
- `close_after_choice`: Auto-hide menu after single selections
- `items`: Array of MulticheckerItem resources defining menu options
- `current_id`: Index of currently selected/focused option
- `prompt_desc`: Translation key for input help text

**Runtime State:**
- `is_activated()`: Returns true when menu is enabled and not blocked

**Signals:**
- `current_id_changed(result: bool, id: int)`: Emitted when selection changes

**Internal Architecture:**
- `keys_root`: Container holding KLKey instances for each menu option
- `lock`: Master KLLock for external blocking control
- SaveLoader integration for automatic state persistence

**Basic Implementation:**
```gdscript
# Create and configure multichecker
var menu = Multichecker.new()
menu.items = [item1, item2, item3]  # MulticheckerItem resources
menu.time_stop = true  # Pause game during menu
add_child(menu)

# Handle selection changes
menu.current_id_changed.connect(func(selected, id):
    if selected:
        print("Player chose option ", id)
)

# Display the menu
menu.set_enabled(true)
```

---

### MulticheckerUI (PanelContainer)
Visual interface controller managing menu display, input visualization, and user interaction.

**Primary Function:**
Serves as the UI bridge between Multichecker logic and visual presentation. Handles dynamic button generation, device-adaptive input feedback, focus management, and menu visibility states. Acts as the visual layer that translates game state into interactive menu elements.

**UI Architecture:**
- `main_container`: Root margin container with consistent spacing
- `prompt`: Input help panel showing current key binding and description
- `collection`: Scrollable menu panel containing interactive buttons
- `button_container`: Horizontal container holding dynamically generated buttons

**Input Device Integration:**
- `prompt_key_image`: Visual gamepad button icons
- `prompt_label`: Text keyboard key display
- `prompt_desc_label`: Translated help text descriptions
- Automatic device detection and visual adaptation

**Core Methods:**
- `set_multichecker(multichecker)`: Assigns and configures UI for a specific Multichecker instance
- `set_showed(value)`: Controls menu visibility and pause state integration
- `_build_buttons(items)`: Creates interactive buttons with Key-Lock state synchronization
- `_update_focus(current_id)`: Manages keyboard/controller navigation focus

**Key Features:**
- Dynamic button generation from MulticheckerItem configurations
- Real-time lock state visualization (enabled/disabled buttons)
- Device-aware input visualization with automatic adaptation
- Focus management for accessibility and controller navigation
- Pause state integration with game time control
- Toggle and single-action button behavior support

**Integration Example:**
```gdscript
# MulticheckerUI is typically autoloaded as MUI
# When a multichecker is enabled, UI automatically updates
var menu = Multichecker.new()
menu.items = [item1, item2, item3]
add_child(menu)
menu.set_enabled(true)  # MUI automatically displays the menu
```

---

### MulticheckerItem (Resource)
Configuration resource defining individual menu options with conditional behavior and actions.

**Primary Function:**
Serves as the data container for each menu choice, defining its appearance, availability conditions, and resulting actions through deep integration with the Key-Lock and Dynamic Expression systems.

**Display Configuration:**
- `name`: Translation key for button text display
- `visible`: Runtime visibility toggle for dynamic menu composition

**Behavioral Properties:**
- `toggled`: Enables persistent on/off toggle mode vs single-action behavior
- `timer`: Auto-deactivation delay in seconds (0 = no auto-reset)

**Key-Lock Integration:**
- `uid`: Unique identifier for cross-scene state persistence and key references
- `lock_expression`: Boolean expression defining availability conditions
- `lock_keys`: Array of key UIDs referenced in lock expressions

**State Management:**
- `reset_when_blocked`: Automatically reset activation when blocked
- `reset_value`: Target state when reset occurs

**Action System:**
- `callables_on_pressed`: Dynamic expressions executed on activation/selection
- `callables_on_released`: Dynamic expressions executed on deactivation (toggle mode only)

**Resource Creation Example:**
```gdscript
# Create a locked menu option that requires a key
var locked_choice = MulticheckerItem.new()
locked_choice.name = "use_special_ability"
locked_choice.uid = "special_ability_unlocked"
locked_choice.lock_expression = "0" # id in `locked_choice.lock_keys`
locked_choice.lock_keys = ["special_key_uid"]
locked_choice.callables_on_pressed = [DynamicExpression.new("activate_special_ability()")]

# Create a toggle option for settings
var toggle_option = MulticheckerItem.new()
toggle_option.name = "enable_music"
toggle_option.toggled = true
toggle_option.callables_on_pressed = [DynamicExpression.new("AudioServer.set_bus_mute(1, false)")]
toggle_option.callables_on_released = [DynamicExpression.new("AudioServer.set_bus_mute(1, true)")]
```

## System Architecture

```
├── MUI (`MulticheckerUI` - visual interface)
│   ├── prompt (input help display)
│   └── collection (menu panel)
│       └── button_container
│           └── Button instances (dynamically generated)
├── ... (autoloaded scripts)
...
└── <current_scene>
    ├── ...
    └── Multichecker (Node)
        ├── SaveLoader (automatic state persistence)
        ├── KLLock (external blocking control)
        ├── keys_root/ (KLKey container)
        │   ├── KLKey_1 (item-specific key instance)
        │   ├── KLKey_2 (item-specific key instance)
        │   └── ... (one per MulticheckerItem)
        └── Integration layer
            ├── Key-Lock system (conditional access)
            ├── Dynamic Expression (action execution)
            └── Input Visualizer (device detection)
```

## Expression Syntax

Lock expressions utilize the same powerful boolean logic syntax as the KLLock system:

**Basic Operators:**
- **Numbers** (0, 1, 2...): Reference keys by their position in the `lock_keys` array
- **`&` or `&&`**: Logical AND operations (both conditions must be true)
- **`|` or `||`**: Logical OR operations (either condition can be true)
- **`!`**: Logical NOT operation (negates the following condition)

**Advanced Syntax:**
- **Parentheses**: Grouping for complex expressions: `(0 | 1) & !2`
- **Compound Logic**: `(has_key_a & has_key_b) | admin_access`
- **Nested Groups**: `((0 | 1) & (2 | 3)) | !4`

**Expression Examples:**
- `"0"`: True if the first key in lock_keys is active
- `"!0"`: True if the first key is NOT active
- `"0 & 1"`: True if both first AND second keys are active
- `"0 | 1"`: True if either first OR second key is active
- `"(0 | 1) & !2"`: True if either first or second key is active, AND third key is not active

## Data Flow & Lifecycle

### 1. Initialization Phase
- Multichecker instantiates KLKey objects for each MulticheckerItem
- UI components are created and connected to key state changes
- SaveLoader begins monitoring current_id for persistence
- Master KLLock connects to external blocking conditions

### 2. Runtime State Evaluation
- KLLock continuously evaluates lock expressions against key states
- Button enabled/disabled states update in real-time
- Visual feedback reflects current availability conditions
- Focus management ensures accessible navigation

### 3. User Interaction Processing
- Input events trigger KLKey activation through the Key-Lock system
- Selection results emit current_id_changed signals
- Dynamic expressions execute with full game context access
- Toggle states persist according to timer configurations

### 4. State Persistence
- SaveLoader automatically captures current_id changes
- KLKey states save through the global Key-Lock registry
- Menu visibility and pause states restore on scene reload
- Cross-session continuity maintained through UID system

### 5. Cleanup & Transitions
- Auto-close behavior handles menu dismissal
- Pause state restoration when menus close
- Connection cleanup prevents memory leaks
- Resource management for dynamic UI elements

## Best Practices & Guidelines

### Design Principles
1. **Progressive Disclosure**: Use lock conditions to reveal options as players progress, maintaining engagement through discovery
2. **Consistent UX**: Maintain uniform interaction patterns across all multichecker instances in your game
3. **Clear Feedback**: Provide immediate visual and audio feedback for all menu interactions

### Technical Guidelines
1. **UID Consistency**: Use descriptive, consistent UIDs across scenes for reliable state persistence
2. **Expression Clarity**: Keep lock expressions readable; use comments for complex logic
3. **Performance Bounds**: Limit menu items to 8-12 maximum for optimal UI performance
4. **Memory Management**: Clean up dynamic connections when multicheckers change to prevent memory leaks

### Accessibility & Usability
1. **Visual States**: Implement clear visual distinctions between locked/unlocked/selected states
2. **Input Clarity**: Ensure input hints remain visible and contextually relevant
3. **Navigation Flow**: Design focus movement that follows logical reading order
4. **Localization**: Use translation keys for all user-facing text

### Testing & Validation
1. **Edge Case Coverage**: Test all lock combinations and state transitions
2. **Device Compatibility**: Verify behavior across keyboard, controller, and touch inputs
3. **State Persistence**: Confirm save/load behavior across scene transitions
4. **Integration Testing**: Validate with Key-Lock and Dynamic Expression dependencies

### Common Patterns
- **Quest Branching**: Use multicheckers for dialogue choices that unlock based on quest progress
- **Ability Systems**: Implement toggle-based ability selection with prerequisite checks
- **Settings Menus**: Create interdependent options with validation logic
- **Inventory Management**: Enable/disable options based on item possession and quantities

