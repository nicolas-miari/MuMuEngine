## Stage Collision

Once we have determined how the tilemaps will be rendered, we need to considered how we are going to implement the collision detection between characters and stage (floor, platforms, walls, etc.) in a way that:
 - Is versatile enough to allow rich level design
 - Is straightforward to implement at runtime
 - Is straightforward to implement in the level editor

The simplest approach is to define the collision shapes in terms of the map tiles. That is, platforms, walls, etc. are perfectly aligned on tile boundaries. This is has quite  afew advantages in terms of implementation:
 - For the level editor, the designer can assign collision properties to each tile. There is no need to introduce new map objects.
 - At runtime, the characters' positions are tested against the collision properties of nearby tiles.

The drawback is obvious: Only horizontal platforms and terrains are possible, and perfectly vertical walls. This basic approach lets you duplicate games such as Super Mario Bros.

 
In order to reproduce arbitrary terrains, we need to define dedicated geometric objects that are independent and decoupled from the tilemap's grid. At runtime, basic collision detection can be implemented against these shapes with relative ease, provided they are split into components basic enough (perhaps with the condition of being convex?). At design time, this requires the implementation of vector editing tools, which is far from trivial.
 
