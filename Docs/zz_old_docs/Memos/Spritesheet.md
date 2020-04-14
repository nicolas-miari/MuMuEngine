A SPRITESHEET consists of 

  - A texture 
  - A database of named rectangular subregions ("subimages").

An ANIMATION FRAME frame consists of:

  - A subimage from a specific spritesheet
  - A floating point value representing display duration, in seconds.
  - A pair of floating point values representing display position offset, relative to the
origin of the relevant coordinate system.

An ANIMATION consists of

  - An ordered sequence of animation frames
  - An integer value representing the number of times the sequence is displayed in succession.

A STATE consists of

  - An animation
  - An unordered set of terminating conditions.

A STATE MACHINE consists of

  - An unordered set of states

The state machine is a component that nodes can have.