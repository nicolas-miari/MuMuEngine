
Each state machine state has a set of **event handlers**, keyed by **event type**.

Each event handler contains an **action**.

When significant events occur (frame update, user input), the applicability of the corresponding handlers is checked.
for example, when there is user input, the current state is queried for event handlers of the appropriate type, and the associated actions are executed. When vSync occurs, the current state's animation is updated, and if the required number of loops is completed as a result (must check loop count before and after updating), then the corresponsing action is executed, etc. 