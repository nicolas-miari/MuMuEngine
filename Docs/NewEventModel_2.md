
### Event Propagation

#### 1. Point Input Events 

Point input events (mouse, touch) propagate as follows:

  1. All point input is forwarded to the Runtime.
  2. The runtime performs hit test on the current scene's nodes, to detect a target for the event. The target must contain the event location within it s hitbox. Additionally, if both a node and one of its children contain the location, the child (i.e., frontmost) node get precedence. If two or more sibling nodes (i.e, same parent) contain the location, the one that is drawn closest to the camera gets precendence. 
  3. If the node has any event handlers for the input, their actions are executed. Otherwise, the event is forwearded to the node's state machine component, if present.
  4. The state machine component searches among the event handlers of its current state, and if appropriates handlers are found, their actions are executed.

#### 2. Time-related Events

The source time-related is the V-sync or display refresh. It is propagated as follows:

  1. The runtime gets notified by the graphics driver of the V-sync event, and calculates the time ellapsed since the last refresh (typically 1/60 of a second, unless frames are 'dropped'). This is used to create an Update event that includes the time information.
  2. The runtime forwards the update event to the current scene's root node, and it propagates it recursively to its children, which do the same, thus propagating it downwards through the whole node hierarchy.
  3. Each node, upon receiving the event, forwards it to each of its components.
  4. In particular, the State Machine component performs the following:
    1. Forward the update event to its current state (i.e., advance animation)
    2. Search the current node's event handlers for any handler triggered by the 'animation loop complete' event, and if the state's animation has just completed the required number of loops, execute the handler's action (in order to evaluate this, the state animation's loop count must be measured before and after forwarding the update event to the state, and comparing both values).

### Action Types

Each event handler responds to a specific type of event (optionally, with a specific set of arguments) by executing an _action_. Actions fall into the following categories:
  1. Transition State: Causes a state machine to move to a specific state. The action is performed by the event handler of an active state towards its own state machine.
  2. Transition Scene: Causes the Runtime to load and transition to a specific scene.
  3. Remove node: Causes the target node to be removed from the hierarchy.