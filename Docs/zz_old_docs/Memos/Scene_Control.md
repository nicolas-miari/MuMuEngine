SceneController is a shared instance manager, accessible globally (both from the framework 
and the host app).

It manages the sustained presentation of scenes, and the temporary transitions between them, 
and takes care of frame updates.

The frame update timer (v-sync) notifies the scene controller of the frame update event,
as well as the time ellapsed since the last frame (Alternatively, the scene controller could
store the system time of the last update, and calculate the difference on every call).

On frame update notification, the Scene Controller:
- Updates the current scene or transition
  - Scenes, in turn, update their node hierarchy.
  - Transitions, in turn, update their source and destination scenes

- Tells the Renderer to draw the current scene or transition.

In addition to handling the update notification, the scene controller also exposes
an interface for presenting scenes and transitioning from the current scene to a 
new one. This calls are typically triggered by user input or game state progress.

---

DESIGN ISSUE: In the particular case of the Metal API, it is the MetalKit view that gets
the V-sync notiication. Find an API-agnostic way to have the scene controller be notified.

SOLUTION:
SceneController implements the callbacks but is not responsible for who calls them or how
that is set up; that is left as a requirement of the specific graphics API.