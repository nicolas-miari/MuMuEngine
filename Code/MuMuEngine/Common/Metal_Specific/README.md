#  Metal Specific

In order to decouple the engine from any specific graphics API, the frameworks _Metal_ 
and _MetalKit_ are referenced (`import`ed) exclusively from the following files:

  - _**MetalGraphicsAPI.swift**_ : Responsible for performing resource management operations 
 that require knowledge of the concrete graphics API being used.
  - _**MetalRenderer.swift**_ : Responsible for drawing every frame.
  - _**Shaders.metal**_: Shader source code.

Everywhere else, graphics-related objects are encapsulated in abstract containers (such
as `Texture` or `Buffer`) so as to keep concerns separated and not pollute the rest of 
the engine code with Metal specifics.

In the (extremely unlikely) event of a migration to another, equivalent low-level GPU API 
(e.g., OpenGL), only substitutes for the above three files should in principle be needed. 
Regardless, setting such a narrow dependency boundary is a good design practice.
