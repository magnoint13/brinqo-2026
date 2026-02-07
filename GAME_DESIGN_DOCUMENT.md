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

### Movement  
- Players control all particles simultaneously using arrow keys or WASD  
- All particles receive the same movement input  
- Particles can separate when encountering walls – one may be blocked while others continue  
- Movement is disabled during collapse animations and particle respawn sequences  

### Collapse Mechanic  
The collapse is the central mechanic of the game:  
A collapse timer counts down from a random duration between 7–15 seconds  
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
- Solid gray obstacles that block particle movement  
- Individual particles can be blocked while others pass, causing the particles to separate  
- Creates strategic complexity as particles can no longer move as a unified line  

### Survival System  
When a collapse occurs in a neutral zone:  
- The randomly selected particle survives at its exact position  
- The survived particle turns gold to distinguish it from new particles  
- Two new blue particles spawn at randomly selected spawn points  
- New particles fade in over 1.5 seconds while the survived particle remains visible  
- The player continues with 3 total particles (1 survived + 2 new)  
- Over multiple neutral collapses, all particles could potentially be survivors in different positions  

## Visual Effects  

### Collapse Animation  
When collapse occurs, a dramatic 1-second animation plays:  
- Converging particles: The two non-selected particles emit particles that accelerate toward the chosen particle  
- Non-selected particles fade out smoothly  
- Selected particle pulses rapidly  
- Shockwave ring expands from the collapse point (blue for neutral, green for win, red for loss)  
- Screen shake effect for added impact  
- For wins/losses: Explosion particles burst outward in the appropriate color  

### Particle Rendering  
- Blue particles: Fresh spawns with glowing aura  
- Gold particles: Survived from previous neutral collapses, rendered with thicker outline  
- Quantum entanglement lines: Faint blue connections between all particles  
- Fade-in effect: New particles gradually appear with increasing opacity  

## Win and Loss Conditions  

### Victory  
- The randomly selected particle must be inside the green zone when collapse occurs  
- Green explosion particles and shockwave effect trigger  
- Success message displays: *"Quantum State Stabilized in Green Zone! You Win!"*  

### Defeat  
- The randomly selected particle is inside any red zone when collapse occurs  
- Red explosion particles and shockwave effect trigger  
- Failure message displays: *"Collapsed in Danger Zone! Game Over!"*  

### Continue  
- The selected particle is in a neutral (gray) area  
- Blue shockwave effect triggers  
- Particle survives, becomes gold, and two new blue particles spawn  
- Collapse timer resets to a new random duration (7–15 seconds)  

## Strategic Depth  
The game creates tension through several strategic layers:  
- **Risk Management**: Players must balance speed (reaching green zone quickly) vs. safety (keeping particles in neutral areas)  
- **Probability Optimization**: Spreading particles across safe spaces increases survival chances during collapse  
- **Wall Navigation**: Using walls to intentionally separate particles for strategic positioning  
- **Timing Pressure**: The unpredictable collapse timer creates urgency without being deterministic  
- **Accumulation**: Survived particles from multiple neutral collapses can create complex formations  

## Technical Implementation  

### Constants  

| Parameter | Value |
|-----------|-------|
| Number of particles | 3 (constant) |
| Particle radius | 8 pixels |
| Movement speed | 3 pixels per frame |
| Collapse timer range | 7–15 seconds (random) |
| Collapse animation duration | 1.0 second |
| Respawn fade-in duration | 1.5 seconds |

### Controls  
- Arrow Keys or WASD: Move all particles  
- Restart Button: Reset the game to initial state  

## Theme and Inspiration  
Quantum Collapse draws inspiration from quantum mechanics concepts:  
- **Superposition**: Multiple particles representing all possible states simultaneously  
- **Wave Function Collapse**: The act of observation (the timer) forces the system into a single definite state  
- **Quantum Entanglement**: Visual connections between particles suggesting they're part of the same quantum system  
- **Measurement Problem**: The outcome is random and unpredictable until the collapse occurs  
- **State Persistence**: Survived particles represent collapsed states that maintain their definite position  

The game translates these abstract physics concepts into intuitive, playable mechanics that create tension and strategic depth without requiring players to understand the underlying science.