Render scene to texture, for post-processing

texture: Set a multisampled texture (has sampleCount > 1)
resolveTexture: Set a normal texture (will use for texture mapping in further passes)
storeAction: Set to .multisampleResolve

Render the scene's nodes to the multisampled color attachment.
Resolve it to the resolve texture.
Sample the resolve texture when drawing full-screen quad. 