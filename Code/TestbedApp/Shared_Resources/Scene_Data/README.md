#  Scene Metadata

Each game scene is instantiated from two resource files:

   1. The **Scene Manifest** file, and
   2. The **Scene Data** file

Thus, a scene in the game which is internally named "MyScene" (scene  names are not visible to the player
but must be unique within each game) requires the following two files:

   1. `MyScene.scenemanifest`
   2. `MyScene.scenedata`
  
  
### The Scene Manifest File
  
  The manifest contains a list of all resurces that should be preloaded and cached _before_ initializing the scene,
  because the latter contains instances of game objects that require the former for their initialization. For example:
  
  - **Texture atlases** (a.k.a. "spritesheets")
  - **Animations** (timed sequences of sprites displayed at one location)
  - **Blueprints** (templates for the creation of reusable game objects, consisting of one or more _components_).

### The Scene Data File

The data file consists of a hierarchy of tree nodes, each representing a game object in the scene or a "container"
for multiple game objects. Each node contains a transformation matrix (relative to the parent node's transformation)
and a list of components that define the attributes of the node. To avoid duplication, nodes can contain a reference to
a previously cached _blueprint_ from which to 'copy' all its components.

The scene data file is basically a 'world layout' map that tells you which objects are placed where, and with what
parent-child relations they should transform. The manifest is a file that tells the engine which reusable resources
should be loaded in advance so that scene instantiation from the data file can run smoothly.
