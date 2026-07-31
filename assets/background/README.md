# Background art slots

Open `scenes/game.tscn` and expand `World > WorldArt`. All background layers are
embedded in the main scene so terrain can be painted while viewing gameplay objects.

- `BaseTerrain`: primary ground tiles.
- `Water`: water and animated water tiles.
- `Paths`: roads, trails, and worn ground.
- `TerrainDetails`: tile-based stones, flowers, and variation.
- `GroundDecals`: free-positioned sprites below actors.
- `GroundProps`: Y-sorted props near actor level.
- `Canopy`: tiles drawn over actors, such as crowns and roofs.
- `ForegroundProps`: free-positioned foreground sprites.
- `WeatherOverlay`: rain, fog, leaves, and similar effects.
- `WorldLighting`: global tint; individual lights can be added later.

For pixel art, import textures with filtering disabled and use one consistent tile size.
