# Brainrot Vault

A 3D steal-and-defend brainrot tycoon for Roblox, built for make.fun's **roblox-brainrot-01** bounty
("Make the best AI Roblox brainrot game").

[![bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/boxi-rgb/brainrot-vault/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/boxi-rgb/brainrot-vault/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

Bounty page: https://make.fun/bounty/roblox-brainrot-01

## The game

Brainrots — absurd meme characters, each earning money every second — stroll down Brainrot Lane.
Catch one, haul it back to your vault while the whole plaza watches, and set it on a pad where it
prints cash. Spend the cash on rarer brainrots, climb the ladder from Common to Mythic (with Gold,
Diamond and Rainbow mutations), and rebirth for a permanent income multiplier.

But the lane is not safe, and neither is your vault:

- **Stealing** — anyone can grab a brainrot from an unlocked vault and run it home. Lock your vault
  to protect the cast, and watch the lock timer.
- **The Tsunami** — every couple of minutes a wave sweeps the lane. Anything still out there —
  brainrots strolling, or one on your back — is washed away. Dash home in time.

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with the vendored
  make.fun library (`vendor/makefun-roblox.ts`, the kit's copy, unchanged).
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`
- `src/shared/` — the brainrot catalogue and tuning (ModuleScripts).
- `src/server/` — world building, spawning, economy, vaults, stealing and the tsunami (server).
- `src/client/` — the HUD, shop and prompts (client).
- `screenshots/` — captures of the game running in Roblox Studio; the first by name is the cover
  and is also the game's first thumbnail on Roblox.
- `PLAY.json` — the published place this entry names.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

## License

MIT — see `LICENSE`.
