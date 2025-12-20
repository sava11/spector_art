# Dynamic Expression

Flexible expression evaluation system that allows executing mathematical, logical expressions and assignments using variables from a data dictionary. Supports NodePath references that are automatically converted to real nodes.

## DynamicExpression

Resource-based expression evaluator that enables dynamic code execution with variable substitution and NodePath resolution.

### Key Features

- **Mathematical Expressions**: Support for arithmetic operations, functions, and complex calculations
- **Logical Expressions**: Boolean operations for conditional logic and state evaluation
- **Assignment Operations**: Direct property modification using `obj.property = value` syntax
- **NodePath Resolution**: Automatic conversion of NodePath references to actual node objects
- **Recursive Processing**: Handles nested dictionaries and arrays with NodePath conversion
- **Error Handling**: Comprehensive validation with detailed error messages
- **Type Safety**: Strict typing for parameters and return values

### Properties

- `expression`: String containing the expression to execute (mathematical, logical, or assignment)
- `data`: Dictionary of variables for use in expressions (keys = variable names, values = variable values)

### Expression Syntax

#### Mathematical Expressions
```gdscript
# Basic arithmetic
"health * 0.5 + armor"

# Complex calculations
"damage * (1.0 - defense / 100.0) + bonus"

# Function calls
"max(health - damage, 0)"
```

#### Logical Expressions
```gdscript
# Boolean operations
"key1 && (key2 || key3)"

# Comparisons
"health > 50 && stamina >= 10"

# Complex conditions
"(player_level >= 5) && (quest_completed || has_item)"
```

#### Assignment Expressions
```gdscript
# Property assignment
"player.health = current_health - damage"

# Variable assignment (limited support)
"result = a + b"  # Note: simple assignments work in some contexts
```

### NodePath Support

DynamicExpression automatically resolves NodePath references in the data dictionary:

```gdscript
# NodePath references are converted to actual nodes
var expr = DynamicExpression.create(
    "player.health = current_health - damage",
    {
        "player": NodePath("../Player"),
        "current_health": 100,
        "damage": 25
    }
)
```

### Methods

#### Core Methods

- `execute(from_what: Node) -> Variant`: Executes the expression with NodePath resolution
- `modify_data(from_what: Node) -> Dictionary[String, Variant]`: Returns data with converted NodePath references
- `validate_expression(test_expression: String = "", variable_names: Array[StringName] = []) -> bool`: Validates expression syntax without execution

#### Utility Methods

- `create(expr: String, context_data: Dictionary[String, Variant] = {}) -> DynamicExpression`: Static factory method
- `get_expression_variables() -> Array[String]`: Returns list of variables used in expression
- `is_assignment_expression() -> bool`: Checks if expression contains assignment
- `to_string() -> String`: Returns debug string representation

### Usage

#### Basic Mathematical Calculation
```gdscript
# Create expression for damage calculation
var damage_expr = DynamicExpression.create(
    "base_damage * multiplier + bonus",
    {
        "base_damage": 50,
        "multiplier": 1.5,
        "bonus": 10
    }
)

# Execute the expression
var final_damage = damage_expr.execute(self)  # Returns 85
```

#### Logical State Evaluation
```gdscript
# Create expression for game state logic
var state_expr = DynamicExpression.create(
    "has_key && (health > 20 || has_shield)",
    {
        "has_key": true,
        "health": 15,
        "has_shield": true
    }
)

# Evaluate condition
var can_progress = state_expr.execute(self)  # Returns true
```

#### Property Modification with NodePath
```gdscript
# Create expression that modifies player health
var health_expr = DynamicExpression.create(
    "player.health = max(player.health - damage, 0)",
    {
        "player": NodePath("../Player"),
        "damage": 30
    }
)

# Execute assignment (modifies actual player node)
health_expr.execute(self)
```

#### Key-Lock System Integration
```gdscript
# Use in lock expressions for complex key dependencies
var lock_expr = DynamicExpression.create(
    "red_key.activated && (blue_key.activated || green_key.activated)",
    {
        "red_key": NodePath("../RedKey"),
        "blue_key": NodePath("../BlueKey"),
        "green_key": NodePath("../GreenKey")
    }
)

# Evaluate lock condition
var is_unlocked = lock_expr.execute(self)
```

#### Combat System Integration
```gdscript
# Dynamic damage calculation based on attacker and defender stats
var combat_expr = DynamicExpression.create(
    "attacker.damage * (1.0 - defender.defense / 100.0) * crit_multiplier",
    {
        "attacker": NodePath("../Player"),
        "defender": NodePath("../Enemy"),
        "crit_multiplier": 1.5  # Set to 1.0 for normal hits
    }
)

var damage_dealt = combat_expr.execute(self)
```

## System Integration

DynamicExpression integrates with other game systems through flexible expression evaluation:

- **Key-Lock System**: Powers logical expressions for complex puzzle dependencies
- **Combat System**: Enables dynamic damage calculations and stat modifications
- **UI System**: Calculates display values and conditional visibility
- **Save/Load System**: Evaluates state conditions for game progression

## Common Patterns

### Damage Calculation Engine
```
CombatSystem
├── DynamicExpression (damage_formula)
├── DynamicExpression (crit_chance)
└── DynamicExpression (status_effects)
```

### Puzzle Logic Controller
```
PuzzleManager
├── DynamicExpression (unlock_condition)
├── DynamicExpression (progress_calculation)
└── DynamicExpression (reward_distribution)
```

### Dynamic UI Updates
```
UIController
├── DynamicExpression (health_percentage)
├── DynamicExpression (stamina_bar)
└── DynamicExpression (progress_display)
```

## Error Handling

DynamicExpression provides comprehensive error handling:

- **Empty expressions** are rejected with clear error messages
- **Invalid NodePath references** generate warnings but don't crash execution
- **Syntax errors** in expressions are caught during parsing
- **Execution errors** (division by zero, invalid operations) are detected and reported
- **Type mismatches** are handled gracefully with appropriate warnings

## Performance Considerations

- NodePath resolution creates deep copies of data dictionaries
- Complex expressions with many variables may impact performance
- Consider caching frequently used expressions for better performance
- Validate expressions during development to catch syntax errors early

## Best Practices

1. **Validate Early**: Use `validate_expression()` during development to catch errors
2. **Cache Expressions**: Reuse DynamicExpression instances for frequently used calculations
3. **NodePath Safety**: Ensure NodePath references are valid when expressions execute
4. **Error Handling**: Always check return values and handle potential null results
5. **Type Consistency**: Ensure data dictionary values match expected types in expressions
