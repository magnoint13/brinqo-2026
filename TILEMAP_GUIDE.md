# TileMapLayer System Guide (Godot 4.6+)

## Overview
Your levels now use **TileMapLayer** (the non-deprecated node type) instead of the old `TileMap`. This system provides built-in grid snapping and makes level creation much faster!

## What Changed
- **Old (Deprecated)**: `TileMap` node with multiple layers
- **New (Current)**: `TileMapLayer` node (single layer, simpler)

## File Structure
- **TileSet Resource**: `res://resources/wall_tiles.tres`
- **Wall Texture**: `res://resources/wall_tile.png`
- **Updated Script**: `res://scripts/main.gd` (now references `$TileMapLayer` instead of `$TileMap`)

## How to Edit Levels

### Step 1: Open a Level Scene
- Double-click any level file (e.g., `Level01.tscn`)

### Step 2: Enable Grid Snapping (Automatic!)
TileMapLayer has built-in grid snapping (16x16 pixels)

### Step 3: Add/Remove Walls
1. **Select the `TileMapLayer` node** in the scene tree
2. **At the bottom of the editor**, click "Select Tile"
3. **Choose the wall tile** (gray square)
4. **Paint walls**: Click/drag on the grid to place tiles
5. **Remove tiles**: Right-click or Shift+click

### Step 4: Creating a New Level
1. Create a new scene inheriting from `Node2D`
2. Add a `TileMapLayer` node
3. Set the `Tile Set` to `res://resources/wall_tiles.tres`
4. Copy other required nodes from existing levels:
   - Background (ColorRect)
   - Zones (Node2D with ColorRect zones)
   - SpawnPoints (Node2D)
   - Particles (Node2D)
   - Camera2D
   - HUD
   - Timers (CollapseTimer, RespawnTimer, AnimationTimer)
5. Attach `res://scripts/main.gd` to the root node

## Example: Level 01 Demo Wall
Level 01 already has a simple wall setup for reference:
- A small wall section around position (256, 256) in the editor
- Uses 16x16 grid tiles
- Collision works automatically

## Technical Details

### Tile Configuration
- **Grid Size**: 16x16 pixels
- **Collision**: Automatic physics layer 0
- **Visual Color**: Gray (#8a8a99)
- **Physics Layer**: 1 (collision_layer=1, collision_mask=1)

### TileSet Structure
```gdscript
# res://resources/wall_tiles.tres
- Tile size: 16x16
- Atlas source with wall_tile.png
- Physics polygon: Rectangle covering the full 16x16 tile
```

## Collision System
No changes needed! Your particle collision works identically:
- Particles use `CharacterBody2D.move_and_collide()`
- TileMapLayer internally creates physics bodies
- Same collision behavior as StaticBody2D walls

## TileMapLayer Properties
- **tile_set**: The TileSet resource to use
- **use_parent_coordinates**: true (positions relative to parent)
- **tile_map_data**: Array of tile coordinates and data
- **y_sort_enabled**: false (for 2D games, usually off)

## Tile Data Format
Each tile is stored as:
```
[x_coordinate, y_coordinate, tile_id]
```
Example: `PackedInt32Array(65536, 0, 0, 32768, 0, 0)`
- `65536`: x=1, y=1 (encoded as x + y * 65536)
- `0`: data index (tile properties)
- `0`: tile ID (0 = first tile in tileset)

## Creating Complex Wall Shapes

### Horizontal Wall
- Click and drag horizontally across grid cells

### Vertical Wall
- Click and drag vertically across grid cells

### L-Shaped Wall
- Draw horizontal, then vertical (or vice versa)

### Hollow Rooms
- Draw walls in a rectangle pattern
- Leave center empty

## Tips for Level Design

1. **Use Zones Reference**: Look at zone positions when placing walls
2. **Test Gameplay**: Run the level frequently to check particle paths
3. **Grid Alignment**: Everything snaps to 16x16 automatically
4. **Multiple Layers**: For multiple wall types, create multiple TileMapLayer nodes

## Common Operations

### Clear All Walls
1. Select TileMapLayer node
2. In Inspector, find "Tile Map Data"
3. Clear the array or delete the node and recreate

### Copy Walls Between Levels
1. In source level, select TileMapLayer
2. Copy (Ctrl+C)
3. In target level, paste (Ctrl+V)

### Change Wall Color
1. Edit `res://resources/wall_tile.png`
2. Or create a new TileSet with different texture
3. Update tile_map_data to use new TileSet

## Troubleshooting

### "No tile set assigned" error
- Click on TileMapLayer node
- In Inspector, find "Tile Set"
- Set it to `res://resources/wall_tiles.tres`

### Can't see tiles in editor
- Make sure TileMapLayer is selected
- Click "Select Tile" at bottom
- Select the wall tile from palette

### Collision not working
- Verify TileMapLayer is selected
- Check that tile has physics enabled in TileSet
- Ensure particles collide with layer 1

### Grid not visible
- In editor toolbar, click "Toggle Grid" (grid icon)
- Or press `G` to toggle grid visibility

## Comparison: Old vs New

| Feature | Old (StaticBody2D) | New (TileMapLayer) |
|---------|------------------|-------------------|
| Placement | Manual positioning | Grid snapping |
| Collision | Manual shapes | Automatic |
| Editing | Duplicate nodes | Paint tiles |
| Speed | Slow | Fast |
| Alignment | Easy to misalign | Perfectly aligned |
| Complexity | Multiple nodes per wall | Single node for all walls |

## Code Reference

### Main Script Update
```gdscript
# scripts/main.gd
@onready var walls = $TileMapLayer  # Changed from $Walls or $TileMap
```

### Collision Detection (No Changes Needed)
```gdscript
# scripts/particles_container.gd
var collision = p.move_and_collide(p.velocity)
# Works identically with TileMapLayer!
```

## Benefits of TileMapLayer
✅ Built-in grid snapping (16x16)
✅ Visual painting (drag to draw walls)
✅ Much faster level creation
✅ Automatic collision from tiles
✅ No manual collision shape editing
✅ Single node for entire level
✅ Memory efficient

## Next Steps
1. Open Level 01 to see the example wall
2. Practice painting tiles in the editor
3. Design your own wall layouts for each level
4. Test gameplay frequently
5. Enjoy faster level creation!
