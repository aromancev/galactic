# IDE Setup
## VSCode

Create `.vscode/launch.json` file with the following contents.
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "GDScript Godot",
            "type": "godot",
            "request": "launch",
            "project": "${workspaceFolder}",
            "port": 6005,
            "debugServer": 6006,
            "address": "tcp://127.0.0.1",
            "launch_game_instance": true,
            "launch_scene": false
        }
    ]
}
```