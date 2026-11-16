# Relic Rush

Relic Rush is a Roblox game project built with Luau, with a Rojo project layout and supporting 3D asset-generation tools.

> **Development status:** Work in progress. This repository is a development snapshot, not a verified production release. Features, balancing, world integration, and runtime behavior may still change.

## Repository layout

- `src/client/` — client controllers and UI
- `src/server/` — server services, world builders, and test runner
- `src/shared/` — shared definitions, networking utilities, types, and audio configuration
- `assets/models/` — exported OBJ/MTL models
- `assets/evidence/` — rendered concept and environment images
- `tools/` — asset generation, world generation, and development utilities
- `default.project.json` — Rojo DataModel mapping

## Working with the project

1. Install Roblox Studio and [Rojo](https://rojo.space/).
2. Clone this repository.
3. Open a terminal in the repository root.
4. Run `rojo serve default.project.json`.
5. Connect to the running Rojo server from the Rojo plugin in Roblox Studio.

The game world is assembled by `src/server/world/WorldBuilder.luau` during server startup. The Rojo mapping includes the client, server, shared modules, lighting, and the market spawn location.

## Asset tooling

The scripts under `tools/` include Blender-based asset and world-generation utilities. They may require Blender and Python packages installed locally. Review each script's prerequisites before running it.

## Security and local files

Do not commit API keys, access tokens, credentials, private keys, personal machine paths, local backups, or generated environment files. Keep local configuration in ignored files and use environment variables or a secrets manager for credentials.

## License

No license has been declared yet. Unless a license is added, all rights remain with the project owner; public visibility does not grant permission to reuse, modify, or redistribute the code or assets.
