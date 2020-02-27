# User Input, Controls, State Machines, Characters...

The basic architecture is that each scene consists of a tree hierarchy of nodes, and each
node can have several 'components' attached to it to give it capabilities (nodes by 
themselves do nothing beyond being parents and children to other nodes). Rendering 
visual content (sprites, tile maps, etc.) is achieved by way of this component architecture.

### Sprite

A very basic component would be a `Sprite`. This component causes the node to be 
rendered as a single, static textured quad (the data to achieve this --texture image and 
coordinates, vertex positions, etc.-- is calculated from a loaded Texture Atlas resource). 
This works for simple, static game objects, but to achieve a richer visual experience, we 
need to go deeper.

### Animation

A more sophisticated component would be `Animation`. This is basically an array of 
sprites that are displayed in succession, each for a predetermined duration, optionally 
looping a finite number of times or indeterminately (forever). At any given moment, the 
component is rendered just like the `Sprite` component mentioned above, only that the 
actual sprite changes over time.

### Character

Actual game characters (player or otherwise) must support several visibly different 
'states', each with a unique visual appearance (animated or static). A component 
supporting this type of behaviour could be a `StateMachine` that encompasses one or 
more states, each with a specific `Sprite` or `Animation` to be displayed while in that 
state, and a clear set of rules determining the conditions under which the state machine 
transitions from one state to another.

### UI Controls

Since everything on screen is redered using the 3D library, we can not take advantage of 
the platform's native UI controls. Instead, they need to be integrated into the display 
hierarchy just as the game objects (but drawn above all game content). In terms of 
internal logic and rendering, UI Controls are pretty much covered by the `StateMachine` 
defined above to implement game characters. In addition, UI controls also need a way to 
receive user input. We achieve this by defining an additional `Responder` component. 
When an input event occurs at the OS SDK level (touch or click), we can hit-test its 
location against the bounding box of all nodes that contain a `Responder` component, 
and once we find the relevant responder, send it the appropriate messages.

