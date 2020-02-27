### Tile Maps

A tilemap is simply a child of a scene's root node (the root node can hold other children that are independent of the map and scrolling, such as HUD/score idicators, etc.). Its children, the `map layers`, are nodes that have a special set of components:
 
  - Parallax: when present, determines how the local transform is computed based on the local transform of the parent (the map as a whole). If the parallax factor (a.k.a. "reltive scrolling speed") is 1.0, the layer moves exactly as the map. If it is 0.5, it scrolls half as much, etc. This component is **optional** (if absent, parallax factor of 1 is assumed).

  - Mesh: A sparse mesh of square cells, all textured with a given tileset. The tile size should be uniform across all layers of the same map.

  - Collision Mask: A set of geometric shapes, positioned in the layer's local coordinate system, representing the 'solid' regions of the layer. Typically, there will be some correlation between the non-empty cells of the mesh and the cells covered by the collision mask's shapes.

All **map objects** (this includes _characters_, wheter player or cpu-controlled) are child nodes of one map layer. A game character that is child of a given map layer can only collide against the collision mask of that layer; the masks of other layers are ignored.

### Bridges

A special map object is the **layer bridge**. It consists of a positioned, oriented line segment, with the following additional properties:
  - It sits in one layer, but contains a reference to a second layer called the 'destination'.

  - When a character sitting in the same layer as the bridge 'enters' it (i.e., the characters extent begins contact with the segment) from a specific side, the character transitions to a state where its collision is tested against the masks of both its current parent layer, and the bridge's destination layer.

  - When the character 'crosses' the bridge completely (i.e., the contact ends with the character on the side opposite from where it entered the bridge), the character is fully transfered to the destination layer (while keeping its global position of course, for visual consistency), and thus from that point on collision is performed against the destination layer's collision mask only. 

1. From the moment the character hits the bridge line, collision is perfromed against both layers's (source and destination) collision masks.
2. Progress along the bridge line is tracked; if the character pulls back out of the bridge, collision returns to source layer only, as if nothing happened. On the other hand, if the character's bounding box fully clears the line, its node is transfered as a child to the destination layer, and collision proceeds there as normal. If the character moves away from the bridge segment without clearing it (e.g., falling from the top of a loop due to insufficient momentum) the last recorded progress along the bridge line is used: If greater than half, transfer to destination layer; if smaller or equal than half, stay on source layer.

Because layer transitions always revolve around movent through the ground, use the character's contact point with the ground instead of its bounding box (which has height extent, away from the ground). This way we are testing a segment (character front-to-rear) against another ('vertical' bridge line).