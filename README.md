# Development
## VSCode Integration
Install [this plugin](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools). Check [launch.json](./vscode/launch.json) for details but it should work out of the box. There is a [known bug](https://github.com/godotengine/godot-vscode-plugin/issues/336) where how reload doesn't work. Use Godot text editor for that.

## Linter and Formatter

Linting and formatting is done using [GDScript Toolkit](https://github.com/Scony/godot-gdscript-toolkit) which requires a Python runtime.

Installation on Windows:
1. [Download](https://www.python.org/downloads/) and run the installer.
	1. Use ADVANCED mode.
	2. Check "pip" and "Create Path variables".
2. Run `pip3 install setuptools` .
3. Run `pip3 install "gdtoolkit==4.*"`.
4. Add `C:\Users\<YOUR_USER>\AppData\Roaming\Python\Python312\Scripts` (The directory where Python was installed + `\Scripts`).

Lint with `gdlint .` and format with `gdformat .`

Optionally, you can install [GDScript Formatter](https://marketplace.visualstudio.com/items?itemName=Razoric.gdscript-toolkit-formatter) and enable `Format on Save` in VSCode.

Order definition errors are not very informative so here is a quick reference for the correct order:
* `tool`
* `classname`
* `extends`
* signals
* enums
* constants
* exports
* public variables
* private variables (prefixed with underscore `_`)
* `onready` public variables
* `onready` private variables (prefixed with underscore `_`)
* other statements

More info [here](https://github.com/Scony/godot-gdscript-toolkit/wiki/3.-Linter).

# Versioning

Game version is stored in `BuildInfo` static class. Version is compatible with [Semantic Versioning](https://semver.org/).

Keep those guidelines in mind when developing:
* If the new game version is no longer backward compatible (e.g. old save files may no longer work or network session with older clients is not possible), MAJOR version number should be increased.
* If the new game version is backward compatible (e.g. can handle old game files and can connect to older clients), MINOR version should be increased.
* If the new version dones not affect compatability at all (e.g. bug fix, purely graphic changes, minor rendering tweaks), PATCH version should be increased.

# Save, Load, Replication
## Usage
To persist or replicate state of a Node:
* Implement `_get_model() -> PackedByteArray` and `set_model(model: PackedByteArray) -> void`.
* Add the Node to group "Replicate" (also available as `Replicator.GROUP` constant) via code or editor.

It is up to the Node how it wants to serialize its model. The recommended way is to use [BinaryPayload](./platform/binary_payload.gd). Nodes themselves are created automatically by `Replicator` along with all parents.

Here are the general guidelines for implementation:
* Make sure that the model returned by `_get_model` represents the full state and no persistent data is lost.
* Make sure that `_get_model` does not mutate the Node state and has no side effects.
* Make sure that `_set_model` will recreate the state correctly from what `_get_model` returns.
* Try to use as little data in the model as possible. For example, if the level is procedurally generated, only the seed needs to be passed to recreate the level.
* Do not make expensive calculations in `_get_model` because it cannot be executed in a separate thread and it *can be called at any time*. For `_set_model` it's ok because it's only called once on initial load.
* Make sure to store game data that spans across multiple levels (game progression, inventories, etc.) in separate Nodes and *are never removed*.

See [BinaryPayload](./platform/binary_payload.gd) binary serialization reccomendations.

**IMPORTANT:** Replication only propagates game model when a player joins. Any incremental changes to the game state should be handled by the Nodes themselves.

## Design
The idea is that the whole game is represented by a model. The model can be collected from the game at any time and sent to other clients or saved. 

This design allows:
* Seamlessly changing the host on the same run.
* Seamlessly switchinbg between cloud saves, dedicated servers, or client. Even having network sessions with a mix of those.
* Have a single mechanism for network replication and game saves.

It also has some drawbacks:
* Game model has to be small because it is sent to each client when they join.
* Any persistent data (progression, inventories, quests, etc.) needs to be saved via a Node that has to be present in the game at all times.

The assumption is that the game model will be relatively small because it is a lightweight roguelike. Since most of the levels are procedurally generated and we can't return to the same levels, we don't need to store any information about them. The only information we need to store at all times is charachter data, achievements, overall game progression, etc.

Model replication and collection is implemented in [Replicator](./game/replicator.gd) and saving and loading is implemented in [Saver](./game/saver). Refer to those for implementation details.

# Utils

All commonly used functionality (often called "utils") is stored in the [platform](./platform/) directory. Here are the guidelines for the contents of this directory:
* It MOST NOT contain anything except for scripts (`*.gd`) or documentaion (`*.md`).
* It MUST be domain-agnostic (i.e. it should not know anything about entities specific to the game).
* Scripts MUST NOT have any dependencies. Not even other scripts from the `platform` directory. Simply put, any script copy-pasted into another project should not break.
