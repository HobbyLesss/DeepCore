# Deep Core
A standalone Godot 4.6.3 / GDScript third-person mining prototype. No external asset or package dependencies.

## Play
Import project.godot in Godot 4.6.3 and press F6 on scenes/main.tscn (or F5).
Choose Play / Continue. Mine the ground, fill your 20-unit backpack, return to the orange terminal, sell, and buy mining-power upgrades. R always returns you safely to the surface.

WASD move; mouse orbit; Space jump; Shift sprint; hold left mouse mine; Tab inventory; Escape pause; E sell within four metres of terminal; U buy +10 damage/s for 30 credits; R recover; F5 save. Quit and selling also save. Saves live in user://deep_core.json with a backup file. Remove both files to reset.

## Architecture
- scenes/main.tscn and scripts/game.gd: scene composition, outpost, menus, HUD and actions.
- player.gd: accelerated CharacterBody3D movement, spring-arm camera, procedural character.
- generation.gd: deterministic seed and clustered geological resources.
- terrain.gd: chunk lookup, persistent edits and localized rebuilds.
- chunk.gd: 16³ packed-byte chunks, exposed-face meshes and chunk collision.
- blocks.gd: resource colors, hardness and values.
- mining.gd: camera ray, reach check, damage, highlight, particles and rewards.
- inventory.gd: independent capacity, sales and upgrade state.
- save_store.gd: versioned temporary-file save, rename and backup fallback.

The finite mine is 32 × 32 × 48 metres (12 chunks), with negative-coordinate support. Permanent retaining walls and a bottom floor enclose it. Generation has three depth bands; the last is truncated at 48 m. No individual voxel nodes. Removal rebuilds the touched chunk and only neighboring chunks sharing the removed cell's boundary. HUD exposes FPS and rebuild count.

## Validate
godot --headless --editor --path . --quit
godot --headless --path . --script tests/smoke.gd

IMPORTANT: the smoke test deletes saves in its user-data directory. Always use isolated XDG_DATA_HOME on Linux:
XDG_DATA_HOME=/workspace/.deepcore/test-data XDG_CONFIG_HOME=/workspace/.deepcore/config XDG_CACHE_HOME=/workspace/.deepcore/cache godot --headless --path . --script tests/smoke.gd

Tests exercise real terrain generation/collision, player motion and jump, ray targeting, mining progress and collection, capacity, sales, negative coordinates, boundary rebuild counts, duplicate prevention and save/restore. Headless validation does not establish graphical quality or Windows runtime compatibility.

Cloud editor/run commands should set XDG_DATA_HOME=/workspace/.deepcore/data, XDG_CONFIG_HOME=/workspace/.deepcore/config and XDG_CACHE_HOME=/workspace/.deepcore/cache because default home paths are read-only.

## Windows export
Install matching Godot 4.6.3 export templates using Editor → Manage Export Templates. Use Project → Export → Windows Desktop, or:
godot --headless --path . --export-release "Windows Desktop" Builds/Windows/DeepCore.exe

## Current limitations / next milestone
Prototype visuals use generated shapes, solid-color ore surfaces and a translucent target cube. No sound assets or tool swing animation yet. Camera sensitivity is exposed in player.gd, without a settings screen. UI and camera need interactive graphical testing. Chunk meshing and collision rebuilds are synchronous; profile before expanding to streaming. Saves have versioning and backup recovery but no comprehensive schema validation. No ending, tutorial or authored exploration objectives yet.

Next milestone: graphical playtesting, sound and pickaxe animation, better ore materials, a guided first expedition, robust save migration, and profiling before threaded chunk streaming.
