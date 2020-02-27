# Relationship Between Scenes and Stages

The scenes define the navigation units of the app; the stages, define the navigation unit 
of the game. Clearly, there is a 'Game' scene (game proper) within which gameplay 
occurs, where the user navigates from stage to stage. When the game finishes or is 
aborted, the app navigates back to (e.g.) the Main Menu scene.

Each scene contains one root node, top of its display hierarchy. Some nodes on the 
hierarchy act as mere containers, grouping siblings to be transformed together, but 
perform not drawing of their own. Other nodes do contain a drawing component (tilemap 
layer, sprite).

The renderer provides drawing support for the gradual transition between any two root 
nodes; it does not matter whether we are transitioning from one scene to another (e.g., 
Main Menu to Game Start) or within the same scene (one stage of the game to the next). 
