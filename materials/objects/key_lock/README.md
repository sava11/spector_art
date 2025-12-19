
# Keys and Locks
A key opens a corresponding lock, enabling interaction with "levers" across different levels or scenes.

## KLD (Key Lock Data)
Central manager for key states and timers. Acts as an autoload singleton that maintains the global state of all keys in the game.

**Key Features:**
- Stores key states in a dictionary: `uid -> { "activated": bool, "blocked": bool }`
- Manages timed key activations with automatic state changes
- Emits signals when key states change (`key_changed`) or timers finish (`key_timer_finished`)
- Provides methods for setting key states and starting/stopping timers

**Usage:**
- Automatically instantiated as a global singleton
- Keys and locks communicate through this central manager
- Handles complex timing logic for temporary key activations

## KLKey
Interactive key object that can be activated/deactivated and has various behavioral properties.

**Key Properties:**
- `uid`: Unique identifier (auto-generated or custom)
- `activate`: Initial activation state on scene load
- `timer`: Duration for timed activation/deactivation
- `reset_when_blocked`: Reset key state when blocked
- `reset_value`: Value to reset to when blocked
- `lock_expression`: Logical expression defining when key gets blocked
- `lock_keys`: Array of key UIDs referenced in the lock expression

**States:**
- `activated`: Current active state (true/false)
- `blocked`: Whether key is blocked from interaction
- `status`: OK or BLOCKED (returned by trigger method)

**Signals:**
- `activated_changed(active: bool)`
- `blocked_changed(blocked: bool)`
- `enabled()`, `disabled()`, `error()` - for visual feedback

**Usage:**
- Place in scene tree to create interactive keys
- Call `trigger()` method to toggle key state
- Connect to signals for visual/audio feedback
- Use lock expressions to create complex dependencies between keys

## KLLock
Lock object that evaluates logical expressions based on key states to determine activation.

**Key Properties:**
- `expression`: Logical expression string (e.g., "(0 | 1) & !2")
- `keys`: Array of key UIDs referenced by index in expression

**Expression Syntax:**
- Use numbers (0, 1, 2...) to reference keys by array index
- `&` or `&&` for AND operations
- `|` or `||` for OR operations
- `!` for NOT operations
- Parentheses for grouping: `(0 | 1) & !2`

**Signals:**
- `activated(active: bool)` - emitted when evaluation result changes

**Usage:**
- Attach to KLKey objects to create blocking conditions
- Expression evaluates key states in real-time
- Automatically updates when referenced keys change state
- Use for creating complex puzzle dependencies 
