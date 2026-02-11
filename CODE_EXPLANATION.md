# Quantum Collapse - Code Explanation

This document explains how the Quantum Collapse game works for people new to Godot game development.

## What is This Game?

Quantum Collapse is a puzzle game where you control 3 particles simultaneously. A random timer counts down to a "quantum collapse" - one particle is randomly selected, and if it's in a safe zone you continue, if it's in a danger zone you lose. The twist is you don't know WHICH particle will be chosen until the collapse happens!

## Project Structure

```
GodotProject/
├── project.godot          # Project settings
├── scenes/
│   ├── main.tscn         # Main game scene
│   └── particle.tscn     # Individual particle scene
└── scripts/
    ├── main.gd           # Main game logic
    ├── particle.gd       # Particle behavior
    └── particles_container.gd  # Manages all 3 particles
```

## Key Concepts

### 1. Nodes and Scenes

In Godot, everything is a **Node**. Nodes are organized in a tree structure (like folders on your computer). A **Scene** is a saved collection of nodes.

**main.tscn** contains:
- Background (ColorRect) - the dark blue background
- Walls (Node2D) - container for wall obstacles  
- Particles (Node2D) - container for the 3 particles
- Camera2D - what the player sees
- CanvasLayer - UI elements (timer, buttons, text)
- Timers - for the collapse countdown

**particle.tscn** contains:
- Particle (CharacterBody2D) - the physics-enabled particle
- CollisionShape2D - circular collision for the particle

### 2. Scripts (GDScript)

Scripts attach to nodes to make them do things. GDScript is similar to Python.

---

## main.gd - The Game Controller

This is the biggest script. It manages the entire game flow.

### Variables

```gdscript
@onready var particles_node = $Particles
```
`@onready` means "get this reference when the game starts". `$Particles` finds the node named "Particles" in the scene tree.

### Game Flow

1. **_ready()** - Runs once when game starts:
   - Sets up random number generator
   - Connects button signals
   - Creates zones and walls
   - Starts the collapse timer

2. **_process(delta)** - Runs every frame (60 times per second):
   - `delta` = time since last frame (about 0.016 seconds)
   - Handles input (keyboard)
   - Updates the timer display
   - Checks if game is over

3. **handle_input()** - Movement:
   ```gdscript
   if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
       direction.x = -1
   ```
   Checks if arrow keys or WASD are pressed, then moves all particles.

4. **_on_collapse_timeout()** - When timer hits zero:
   - Picks one random particle
   - Plays collapse animation
   - Checks which zone that particle is in

5. **check_zone()** - Determines win/lose:
   - Green zone (top right) = WIN
   - Red zones = LOSE  
   - Neutral zone = Survive and respawn 2 new particles

### Creating Visual Elements

```gdscript
func create_zones():
    var green = ColorRect.new()
    green.position = Vector2(650, 250)
    green.size = Vector2(100, 100)
    green.color = Color(0.2, 1.0, 0.2, 0.4)
```
This creates the colored rectangles you see. `ColorRect` is a built-in Godot node for drawing colored rectangles.

---

## particle.gd - Individual Particle

Each blue/yellow dot is a Particle.

### What it does:

```gdscript
extends CharacterBody2D
```
`CharacterBody2D` is a special Godot node for physics-based movement. It handles:
- Collision detection
- Sliding along walls
- Velocity/position updates

### Key Functions:

**setup(is_new)** - Called when particle spawns:
- Sets color (blue = new, yellow = survived collapse)
- Sets transparency (new particles fade in)

**_draw()** - Draws the particle:
```gdscript
func _draw():
    var color = Color(1.0, 0.84, 0.0) if is_survived else Color(0.39, 0.59, 1.0)
    draw_circle(Vector2.ZERO, RADIUS, color)
```
`_draw()` is Godot's built-in function for custom drawing. It draws:
- Outer colored circle (gold or blue)
- Inner white circle (for style)
- Glow effect if survived

**set_survived(value)** - Changes particle color:
- `true` = gold (survived a collapse)
- `false` = blue (normal)

---

## particles_container.gd - Managing All Particles

This script sits on the "Particles" node and manages the array of 3 particles.

### Key Functions:

**spawn_initial_particles()** - Creates starting particles:
```gdscript
for pos in SPAWN_POSITIONS:
	var p = particle_scene.instantiate()
	p.position = pos
	p.setup(true)
	add_child(p)
	particles.append(p)
```
- `preload("res://scenes/particle.tscn")` - Loads the particle scene file
- `instantiate()` - Creates a new instance from the scene
- `add_child(p)` - Adds it to the scene tree
- `particles.append(p)` - Adds to our array to track it

**respawn_two_particles()** - After neutral collapse:
- Spawns 2 new blue particles at random spawn points
- Uses Tween to fade them in over 1.5 seconds

**clear_non_survived()** - Removes dead particles:
- Only keeps the survived particle
- Deletes others from scene and array

**apply_movement()** - Moves all particles:
```gdscript
p.velocity = direction * speed
var collision = p.move_and_collide(p.velocity)
```
- `move_and_collide()` is Godot's built-in collision detection
- If collision with wall, it slides along the wall
- Keeps particles in screen bounds

---

## How Collisions Work

Godot has built-in physics! Here's the chain:

1. **StaticBody2D** (walls) - Don't move, block other bodies
2. **CollisionShape2D** - Defines the shape for collision
3. **RectangleShape2D** - A rectangle collision shape
4. **move_and_collide()** - Asks physics engine: "Can I move here?"

When a particle hits a wall:
- Physics engine detects collision
- Returns collision info (normal vector, remainder, etc.)
- We use `collision.get_remainder().slide()` to slide along the wall

---

## Timers

Timers are nodes that count down and trigger events.

**collapse_timer** (7-15 seconds):
- When it runs out = quantum collapse happens
- Random duration so player can't predict it

**respawn_timer** (0.5 seconds):
- Brief pause after collapse before respawning
- Lets player see what happened

**animation_timer** (1.0 second):
- How long the collapse effect plays
- During this time, player can't move

---

## The Collapse Logic

When timer hits zero:

1. Pick random particle: `particles[randi() % particles.size()]`
2. Check its position against zone rectangles
3. If green zone → Win
4. If red zone → Lose  
5. If neutral → Keep particle (turns gold), respawn 2 new ones

The key trick: Only ONE particle matters. The other two disappear. This creates the "quantum uncertainty" - you have to position ALL particles safely because you don't know which will be chosen!

---

## Signals

Godot uses **signals** for communication between nodes:

```gdscript
restart_button.pressed.connect(_on_restart_pressed)
```
This says: "When the button emits 'pressed', call my function."

Other signals used:
- `collapse_timer.timeout` → collapse happens
- `respawn_timer.timeout` → spawn new particles
- `animation_timer.timeout` → check win/lose

---

## Vector2 and Movement

`Vector2(x, y)` represents positions and directions:
- `Vector2(1, 0)` = right
- `Vector2(0, -1)` = up
- `Vector2(0.707, 0.707)` = diagonal (normalized)

`.normalized()` makes the vector length = 1, so diagonal movement isn't faster.

---

## Tips for Modifying

**Change speed:** Edit `BALL_SPEED` in main.gd (default 300)

**Add more particles:** Change `NUM_BALLS` constant

**Change zones:** Edit the Rect2 values in `check_zone()` and `create_zones()`

**Change colors:** Edit the Color values in `particle.gd` and `main.gd`

**Change collapse timer:** Edit `COLLAPSE_MIN_TIME` and `COLLAPSE_MAX_TIME`

---

## Common Godot Terms

- **Node**: Basic building block of games
- **Scene**: A saved tree of nodes
- **Script**: Code attached to a node
- **Signal**: Event system for communication
- **Tween**: Smooth animation between values
- **Instance**: A created copy of a scene
- **Physics Body**: Object that interacts with physics
- **Collision Shape**: Defines hitbox for physics

---

## Troubleshooting

**Particles not moving?** 
- Make sure physics is initialized (call `move_and_slide()` in `_ready()`)

**Zones not visible?**
- Check that zones node is at correct index in scene tree
- Verify ColorRect has proper position/size

**Collision not working?**
- Ensure StaticBody2D has CollisionShape2D child
- Check that collision shapes overlap in editor

**Respawn not working?**
- Make sure survived particle is marked before clearing others
- Verify particles array is properly rebuilt

---

## Learning More

- **Godot Documentation**: https://docs.godotengine.org/
- **GDScript Reference**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **CharacterBody2D**: https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html
- **Vector Math**: Essential for game development!

This game demonstrates: nodes, scenes, physics, timers, signals, arrays, vectors, and collision detection - the core of most Godot games!
