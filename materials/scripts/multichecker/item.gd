## MulticheckerItem - Configuration resource for individual menu options in multichecker systems.
##
## This resource defines the complete behavior, appearance, and logic for each choice in a multichecker menu.
## Supports conditional visibility, Key-Lock integration for access control, toggle/push-button modes,
## and dynamic expression execution for complex game logic. Acts as the bridge between UI presentation
## and game state management through the Key-Lock system.
## [br][br]
## [b]Key Features:[/b]
## - Conditional visibility based on game state or external factors
## - Full Key-Lock system integration for complex access conditions
## - Dynamic expression execution on activation/deactivation
## - Toggle mode for persistent state changes (on/off switches)
## - Auto-reset functionality with configurable timers
## - Translation-ready text display with key-based localization

extends Resource
class_name MulticheckerItem

signal visible_changed(result:bool)

# =========================================================
# Basic Configuration
# =========================================================
@export var uid:="@path"                           # Unique identifier for key-lock system
@export var name:String="capability_name"          # Display name (translation key)
@export var visible:=true:                         # UI visibility control
	set(value):
		visible=value
		visible_changed.emit(value)
@export var toggled:=false                         # Toggle button behavior
@export var timer:float=0                          # Auto-reset timer in seconds
# =========================================================
# Reset Configuration
# =========================================================
@export_group("reset","reset")
@export var reset_when_blocked:bool=false         # Reset state when blocked
@export var reset_value:bool=false                # Value to reset to

# =========================================================
# Lock Configuration (KLKey integration)
# =========================================================
@export_group("lock","lock")
@export var lock_expression: String               # Logical expression for locking
@export var lock_keys: Array[String]              # Required key UIDs for unlocking

# =========================================================
# Action Configuration
# =========================================================
@export_group("callables","callables_on_")
@export var callables_on_pressed:Array[DynamicExpression]   # Actions on activation
@export var callables_on_released:Array[DynamicExpression]  # Actions on deactivation (toggle only)
