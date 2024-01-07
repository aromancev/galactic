# Mission
Highest-level entity that represents a particular mission. It could also be an intermediate
location like a base or a ship.

## Components
There are a number of basic "building blocks" that define a mission:
* Level - represents how level looks like and what it contains.
* Unit - basic entity that represents any charachter in the mission. It can be an NPC, a player, an enemy
, etc.
* Controller - represents a way to control Unit behaviour.
* Ability - Represents unit behaviour.

## Modular Desing
In order to support modding and provide better modularization of components, a file-based modular approach is implemented.
