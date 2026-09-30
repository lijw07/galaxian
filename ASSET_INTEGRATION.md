# Approved Art Integration

The art and music approved in this chat are integrated into the existing single-player game. The original gameplay, scoring, dive patterns, and synthesized sound effects remain in place.

## Scenes

- `scenes/main.tscn`: launchable single-player game and menu flow.
- `scenes/asset_gallery.tscn`: animated assets with green hitbox outlines; run this scene to inspect the collision sizes.
- `scenes/entities/player.tscn`: player ship and inset 10x8 damage area.
- `scenes/entities/green_enemy.tscn`, `violet_enemy.tscn`, `red_enemy.tscn`, and `boss.tscn`: three-frame enemies and 12x8 body damage areas.
- `scenes/entities/player_shot.tscn` and `enemy_shot.tscn`: 1x4 and 1x3 projectile areas aligned to the visible pixels.
- `scenes/effects/explosion.tscn`: four explosion frames followed by a transparent end frame; no damage area.
- `scenes/effects/starfield.tscn`: scrolling background; no collisions.
- `scenes/ui/`: title, HUD, pause, game over, high score, life icon, and wave flag scenes. Decorative/UI assets do not collide.
- `scenes/game.tscn`: existing game orchestration, now instantiating the entity/effect scenes.

## Collision Contract

| Layer | Objects | Mask |
| --- | --- | --- |
| 1 | Player | Enemies and enemy shots |
| 2 | Enemies | Player and player shots |
| 3 | Player shots | Enemies |
| 4 | Enemy shots | Player |

Each entity uses an `Area2D` and an instance-local `RectangleShape2D`. The scene's shape also supplies the dimensions for the existing gameplay hit checks. Projectiles retain swept rectangle checks between their previous and current positions to prevent tunneling. Damage is resolved once by `Game`; overlap signals do not independently apply damage. Enemy damage areas remain axis-aligned while the artwork rotates during dives. Hidden enemies and inactive/dead players have their areas disabled.

## Art and Music

- `assets/approved/frames/` retains all 15 approved 24x24 sprite PNGs unchanged.
- `assets/sprites/` contains three-frame strips, projectiles, flag, and explosion strips.
- `assets/approved/reference/` retains the approved UI mockups and symmetry report. UI screens are implemented with live text and interaction, not screenshots.
- `assets/ui/` contains a crisp bitmap glyph atlas, title logo, and selection cursor.
- `assets/music/` contains the three approved WAVs, their scores, and metadata. Title/gameplay loop; game-over plays once. Pause suspends music playback.
- `assets/approved/manifest.json` records source descriptions and SHA-256 digests for all 40 copied/derived files.

Texture imports use lossless compression, no mipmaps, no transparent-edge color processing, and nearest filtering. All 15 imported frames pass exact RGBA symmetry and source-frame comparison checks.

## Controls

Arrow keys or A/D move, Space fires, and Escape pauses. Menu navigation uses Up/Down and Enter or Space. Menu items also accept clicks/taps; the existing touch drag-and-fire input is retained.

## Rebuild and Verify

Run `node tools/import_approved_art.cjs REVIEW_DIRECTORY ORIGINAL_REVIEW_IMAGE` to rebuild assets. The importer uses `sharp`; set `SHARP_MODULE` to its module location on another machine. Run `node tools/build_asset_scenes.cjs` to rebuild generated scenes. The manually maintained gallery is separate.

Run Godot's editor import, then `--headless --script res://tools/configure_imports.gd`, then import again so the pixel-preserving settings take effect. Run with the project path set to this directory:

```sh
godot --headless --path . --script res://tests/asset_integration.gd
godot --path . --script res://tests/visual_smoke.gd
```

Validation: 118 integration checks passed; nine rendered captures cover title, high scores, gameplay, shooting, pause, game over, portrait/tablet-sized windows, and collision gallery. Final native macOS runs contain no errors or warnings. Tests use separate score files in `tests/output/` and do not change the player's saved high score. Mobile devices and web exports have not been playtested.
