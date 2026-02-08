# Quantum Collapse
Game Design Document

## Overview
Quantum Collapse is a minimalist puzzle game inspired by quantum mechanics, specifically the concept of wavefunction collapse. Players control multiple particles simultaneously until a random collapse event forces them into a single quantum state, determining success or failure based on the particle's location.

## Core Concept
The game simulates quantum superposition: multiple possibilities exist simultaneously until observation (collapse) forces a single outcome. Players must navigate their particles through a dangerous environment, knowing that at any moment, their quantum state will collapse into one random position.

## Game Mechanics

### Particles
- The game maintains exactly 3 particles at all times
- Each particle has its own spawn position on the left side of the play area
- All particles move together in unison when the player provides input
- Particles are rendered as blue orbs with glowing effects and connecting lines representing quantum entanglement
- Survived particles (from previous neutral collapses) appear gold/yellow instead of blue
- Blue color: RGB(0.39, 0.59, 1.0)
- Gold color: RGB(1.0, 0.84, 0.0)

### Movement
- Players control all particles simultaneously using arrow keys or WASD
- All particles receive the same movement input
- Movement speed: 300 pixels per second
- Particles can separate when encountering walls – one may be blocked while others continue
- Movement is disabled during collapse animations and particle respawn sequences
- Particles wrap around screen edges (800x600 viewport)
- Particles can collide with each other, bouncing off one another

### Collapse Mechanic
The collapse is the central mechanic of the game:
- A collapse timer counts down from a random duration between 7–15 seconds
- When the timer reaches zero, one particle is randomly selected
- Only the selected particle's position is evaluated
- The other two particles disappear during the collapse
- The outcome is determined by which zone contains the selected particle

### Zones
The play area contains three types of zones:

| Zone Type | Effect |
|-----------|--------|
| Green Zone | The safe zone located on the right side. If the collapsed particle is here, the player wins the game. |
| Red Zones | Danger zones scattered throughout the play area. If the collapsed particle is in any red zone, the game ends in failure. |
| Neutral Zone | Any gray/empty area. If the collapsed particle is here, it survives and remains at its current position. Two new particles spawn at random spawn points, and the collapse timer resets. Total particles remain at 3. |

### Walls
- Solid gray obstacles that block particle movement using TileMapLayer (16x16 grid)
- Individual particles can be blocked while others pass, causing the particles to separate
- Creates strategic complexity as particles can no longer move as a unified line

### Survival System
When a collapse occurs in a neutral zone:
- The randomly selected particle survives at its exact position
- The survived particle turns gold to distinguish it from new particles
- Two new blue particles spawn at randomly selected spawn points
- New particles fade in over 0.5 seconds while the survived particle remains visible
- The player continues with 3 total particles (1 survived + 2 new)
- Over multiple neutral collapses, all particles could potentially be survivors in different positions
- Survived particles revert to blue after 1.5 seconds once respawn completes

## Visual Effects

### Collapse Animation
When collapse occurs, a dramatic 0.8-second animation plays:
- Subtle screen shake intensity (2.0, 0.2 duration)
- Dissolve effect: Non-selected particles emit particles and fade out with scale shrink
- Selected particle stabilizes with yellow ring animation and gentle scale pulse
- Shockwave ring expands from the collapse point (color varies by outcome)
- Screen shake effect for added impact
- For wins/losses: Burst VFX particles in appropriate color

### Particle Rendering
- Blue particles: Fresh spawns with glowing aura
- Gold particles: Survived from previous neutral collapses, rendered with survivor aura effect
- Quantum entanglement lines: Faint blue connections (RGB 0.3, 0.6, 1.0, 0.4) between all particles
- Fade-in effect: New particles gradually appear with increasing opacity
- Trail particles: Emit when particle is moving, with amount ratio based on velocity
- Survivor ring: Animated arc that pulses during collapse

### VFX System
The game includes a complete VFX system using procedural textures (no external assets):
- **ExplosionVFX**: Burst particles for win/loss states
- **BurstVFX**: Expanding ring with spark burst
- **DissolveVFX**: Particles dissolving with scale and alpha fade
- **StabilizeVFX**: Selected particle stabilization effect

## Win and Loss Conditions

### Victory
- The randomly selected particle must be inside the green zone when collapse occurs
- Green burst particles and shockwave effect trigger
- Screen shake (2.5 intensity, 0.4 duration)
- Green flash overlay
- Success message: *"QUANTUM STATE STABILIZED! YOU WIN!"*
- Level completion triggers level unlock progression

### Defeat
- The randomly selected particle is inside any red zone when collapse occurs
- Red burst particles and shockwave effect trigger
- Screen shake (2.0 intensity, 0.3 duration)
- Red flash overlay
- Failure message: *"COLLAPSED IN DANGER ZONE! GAME OVER!"*

### Continue
- The selected particle is in a neutral (gray) area
- Particle survives, becomes gold, and two new blue particles spawn
- Status message: *"Particle survived! Respawning..."*
- Collapse timer resets to a new random duration (7–15 seconds)

## Level System

### Level Progression
- Total of 5 levels (Level01 through Level05)
- Level select screen shows unlocked levels
- Levels unlock sequentially: completing Level N unlocks Level N+1
- Level 1 is unlocked by default
- Progress saved to `user://quantum_collapse_save.save`

### Level Structure
Each level contains:
- TileMapLayer for walls (16x16 grid tiles)
- Red zone TileMapLayer for danger areas
- Green zone TileMapLayer for win area
- SpawnPoint nodes for particle spawn locations
- Camera2D (fixed, no zoom)
- HUD with timer, progress bar, status labels
- Pause menu accessible via Escape key

## UI Elements

### HUD
- **Timer Label**: Shows countdown or status messages
- **Status Label**: Displays collapse results (win/lose/survive messages)
- **Progress Bar**: Visual indicator of time until next collapse (color shifts green→yellow→red)
- **Restart Button**: Resets current level
- **Menu Button**: Opens pause menu

### Pause Menu
- Accessible via Escape key or Menu button
- **Resume Button**: Return to gameplay
- **Restart Button**: Restart current level
- **Level Select Button**: Go to level selection
- **Main Menu Button**: Return to title screen

### Main Menu
- **Start Button**: Begin at Level 1
- **Level Select Button**: Choose unlocked levels
- **Quit Button**: Exit game

### Screen Resolution
- Viewport: 800x600 pixels
- Canvas items stretch mode
- Compatible rendering (works on all platforms)

## Strategic Depth
The game creates tension through several strategic layers:
- **Risk Management**: Players must balance speed (reaching green zone quickly) vs. safety (keeping particles in neutral areas)
- **Probability Optimization**: Spreading particles across safe spaces increases survival chances during collapse
- **Wall Navigation**: Using walls to intentionally separate particles for strategic positioning
- **Timing Pressure**: The unpredictable collapse timer creates urgency without being deterministic
- **Accumulation**: Survived particles from multiple neutral collapses can create complex formations
- **Particle Collision**: Particles bounce off each other, adding another layer of unpredictability

## Technical Implementation

### Constants

| Parameter | Value |
|-----------|-------|
| Number of particles | 3 (constant) |
| Particle radius | 8 pixels |
| Movement speed | 300 pixels/second |
| Collapse timer range | 7–15 seconds (random) |
| Collapse animation duration | 0.8 seconds |
| Respawn fade-in duration | 0.5 seconds |
| Survivor reversion delay | 1.5 seconds |
| Screen wrap X | 0 ↔ 800 pixels |
| Screen wrap Y | 0 ↔ 600 pixels |
| Trail particle amount | 0.8 when moving, 0.2 when stationary |

### Controls
- Arrow Keys or WASD: Move all particles
- Escape: Toggle pause menu
- Restart Button: Reset the game to initial state
- Menu Button: Open pause menu

### Autoloads (Singletons)
- **GameManager**: Manages level progression, save/load system, scene transitions
- **VFXSpawner**: Centralized VFX spawning system for all visual effects

### File Structure
```
brinqo-2026/
├── project.godot              # Godot 4.6 project config
├── autoload/
│   └── GameManager.gd         # Level progression & save system
├── scripts/
│   ├── main.gd                # Main game controller
│   ├── particle.gd            # Individual particle behavior
│   ├── particles_container.gd # Particle management & movement
│   ├── VFXManager.gd          # VFX management
│   ├── VFXSpawner.gd          # VFX spawning helper
│   └── SpawnPoint.gd          # Spawn point logic
├── scenes/
│   ├── particle.tscn          # Particle scene
│   ├── CollapseEffect.tscn    # Collapse animation scene
│   ├── VFXManager.tscn        # VFX manager scene
│   └── vfx/                   # VFX scenes (Explosion, Burst, Dissolve, Stabilize)
├── levels/
│   ├── Level01.tscn           # Level 1
│   ├── Level02.tscn           # Level 2
│   ├── Level03.tscn           # Level 3
│   ├── Level04.tscn           # Level 4
│   └── Level05.tscn           # Level 5
├── resources/
│   ├── wall_tiles.tres        # Wall tile set (16x16)
│   ├── red_zone_tiles.tres    # Red zone tile set
│   └── green_zone_tiles.tres  # Green zone tile set
├── entities/
│   └── SpawnPoint.tscn        # Spawn point entity
├── ui/
│   ├── MainMenu.gd/tscn       # Main menu
│   ├── LevelSelect.gd/tscn    # Level selection
│   └── HUD.gd/tscn            # Heads-up display
└── GAME_DESIGN_DOCUMENT.md    # This document
```

### Rendering
- Renderer: Compatibility mode (works on all platforms)
- Physics: Jolt Physics engine (3D physics configured, 2D gameplay)
- Procedural textures using GradientTexture2D (no external image assets required)

## Theme and Inspiration
Quantum Collapse draws inspiration from quantum mechanics concepts:
- **Superposition**: Multiple particles representing all possible states simultaneously
- **Wave Function Collapse**: The act of observation (the timer) forces the system into a single definite state
- **Quantum Entanglement**: Visual connections between particles suggesting they're part of the same quantum system
- **Measurement Problem**: The outcome is random and unpredictable until the collapse occurs
- **State Persistence**: Survived particles represent collapsed states that maintain their definite position

The game translates these abstract physics concepts into intuitive, playable mechanics that create tension and strategic depth without requiring players to understand the underlying science.
