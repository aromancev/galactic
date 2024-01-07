# Mission
Highest-level entity that represents a particular mission. It could also be an intermediate
location like a base or a ship.

## Components
There are a number of basic "building blocks" that define a mission:
* [Level](./mission/) - represents how level looks like and what it contains.
* [Unit](./mission/unit.gd) - basic entity that represents any charachter in the mission such as a NPC, a player, an enemy
, etc.
* [Controller](./mission/controller.gd) - represents a way to control Unit behaviour such as player or AI.
* [Ability](./mission/ability.gd) - represents Unit behaviour such as move or attack.

## Modular Design
The goal of modular design is to allow an easy way to create new content. This allows straightforward modding and overall better modularization of components. 

The main design aspect is that all of the game components can be added by adding a new file to a specific directory. No global registries or modification of the game systems is required. 

There is a tradeoff for such a design, however. Reduced complexity in one place usually leads to increased complexity in another. It is a concious choice to reduce complexity for adding new content at the cost of complexity core game systems.

To create a new component a new directory needs to be created at a predefined location. The name of this directory is the primary identificator of that component. In the code it is referred to as `slug`.

To optimize network performance each `slug` has a corresponding numerical identificator - `slug_id`. This identificator can be used to pass a reference to the component via RPC, for example. All base component classes provide static functions to retrieve `slug` and `slug_id`.

**IMPORTANT:** Never persist `slug_id`. Since it is constructed at runtime, there is no guarantee that it will be the same for each `slug` if a component was added or removed. Simply put, patches or mods will change all `slug` <-> `slug_id` mapping. If saving game, always use `slug`, NOT `slug_id`.
