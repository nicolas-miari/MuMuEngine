
Portals

## 1. Within a Map

When linking between two different locations of the same map layer, or two locations in
different layers of the same map, simply scroll the view into the destination (animation
easing could be made configurable). Optionally, perform some animation on the player
character's sprite, at the origin and/or destination (e.g.: sparks for an energy transporter
à la Star Trek, fade out/fade in for a door into a dark room, etc.).

## 2. Between Maps

Each map resides in its own scene, off-screen from all the other maps, so transition from
the scene hosting the source map to the one hosting the destination. The transition can
be either cross dissolve or -more commonly- sequential fade. In the former case, it would
be nice to support preserving the player character's position on screen (provided the
destination map's scroll limits allow it) and other visual attributes during the transition, for
the sake of visual consistency.

The engine needs to have a configurable option to determine whether maps are reset on
revisit, or if they preserve their state (broken objects, collected items, revealed secret
passages, position of movable platforms, defeated enemies, etc.). For simplicity and in
line with existing games and tradition, this should be an all-or-nothing optons that
applies to _all_ maps equally.
However, it should still be configurable on a per-entity basis. For example: on revisit,
enemies re-spawn, platforms and doors return to their initial position, but collected items
do not.


## 3. Between Stages

Transitions between stages distinguish two cases: Free exit and Goal Exit. Which pattern
applies should be a global setting that aplies to the whole game.

### 3.1 Free Exit

In the free exit mode, the player character simple exits the current stage into a global
"World Map" which he can navigate in order to enter one of many stages. The transition
should be sequential fade, perhaps a telop in between for comedic effect (e.g.,
displaying the words "Back to map...").

Like in tha case of maps, the engine needs to know whether reentered stages are reset
or preserve their state.

### 3.2 Goal Exit

The goal exit from a stage implies some accomplishment, so typically involves displaying
some result stats -either in place (like Sonic) or in a special telop screen (e.g.:
Prehistorik 2), before transporting the player into the beginning of the next, _sequential_
stage.
