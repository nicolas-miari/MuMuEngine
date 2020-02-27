# Game Controller Architecture

Game controllers are discovered on launch and assigned 'player' numbers  in order (i.e., "player 1", "player 2", etc.). Of course, for single-player games any controller after the first is ignored for the purpose of gameplay (not for app navigation, though).

Each controller discovered is configured with the appropriate callbacks.
On control value change, the following happens:

If the current scene is gameplay, the input is forwarded to the correspnding player character's character controller component.

Make sure that control callbacks are called on the main  thread, and if not, dispatch them to the main queue.
