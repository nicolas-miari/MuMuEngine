Cross dissolve can be implemented with a special shader
that assigns the weighted sum of two samplers to each vertex,
instead of drawing two overlapping quads and depend on alpha 
blending on the color buffer.

(This approach does not work for more complex tranitions that 
rely on -e.g.- the stencil buffer.)