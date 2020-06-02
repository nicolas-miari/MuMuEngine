
Assume that each image file generates one texture, and that each texture is used by at most one tileset OR one spritesheet (two sets of texture coordinates "reinterpreting" the same set of pixels in two different ways does not make much sense, unless you craft your game specifically around that concept, cleverly; a 0.0001% edge case.).

In that case, reference count should be maintained on a per-Spritesheet (Tileset) basis, not per-texture. When a spritesheet (tileset) is referenced by zero sprites (layers), it can be deallocated if necessary, at which point the texture, initimately associated with the spritesheet (tileset) is also deallocated and thus purged from memory.

(This purging only applies to mobile platforms, where the concept of low memory and memory warnings exist - and also the CPU/GPU memory is shared).

On metal, it should be enough to deallocate the MTLTexture instance via ARC. On OpenGL (ES), we need to explicitly call glDeleteTextures().

Each sprite created from a spritesheet increases the reference count of said sheet on instantiation, and decreases it on deallocation (the exact same applies to map layers created from tilesets).

Before loading each tilemap, a "gathering" phase takes place where all necessary resources are listed, and loaded asynchronously if not on cache. First, the tilesets for each layer are counted. Next, the spritesheets needed to load all map objects.

The tilemaps will certainly use a data source protocol to have the scene or other controller object provide it with map object instances on demand; We must determine how will the map layers reference the objects they contain.

There needs to be a translation layer somewhere; map objects will typically be "clones" of some entity defined elsewhere in the engine.

We need a library of "entities".

The map layer stores instances of each entity by name. Per-instance attributes are stored in an adjoint dictionary. So each instance of a map entity consists of a dictionary at a grid location of a given layer (the dictionary contains both the entity name -its 'class'- and the extra, custom attributes).

Each map must also have (in addition to its layers) a 'digest' or list of all resources needed to instantiate its entities (this digest is assembled by the Editor on export), so that resources can be loaded upfront, in bulk, instead of checking whether a resource is in cache or not each time a new entity instance is requested (i.e., "on demand"). 