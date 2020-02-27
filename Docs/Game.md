
The app has a fixed number of save game slots.

The first mode works like Sonic The Hedgehog games:

Each slot holds game progress information in the form of:
  - Last stage reached (in the case of So nic, always Act 1 of the relevant Zone)
  - Number of lives left
  - Items obtained/secrets unlocked

Whenever the user clears a new level, the above information is automatically saved to the slot.
If a user loses several lives, but does not complete the current stage and quits the game, the slot remains unchanged and the next time they start the game, the lost lives are 'restored' (and any further progress is lost).


The second mode is popular among modern games. The user has essentially an infinite number of lives, so there is no concept of 'Game Over'. Instead, they play and play and play until they achieve all the goals of the game (clear stages, defeat bosses, obtain items, etc.).

The player loads an existing game from one of the slots and resumes from where they left off. If no game is saved in any slot, they start a fresh game anew, and it is immediately saved in one of the slots. 

Game Modes

  - Limited Lives: Once the player loses all their lives, they must start over. Optionally, a 'continue' option can be set up. TODO: Decide what happens with the saved game on Game Over.

  - Unlimited Lives: The player can retry indefinitely until they clear the stage. This mode assumes that the real obstacle is the sheer difficulty of some levels. 
