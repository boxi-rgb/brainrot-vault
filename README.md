# Brainrot Vault

![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)
![rank](https://make.fun/badge/roblox-brainrot-01/boxi-rgb/brainrot-vault/rank.svg)
![reward](https://make.fun/badge/roblox-brainrot-01/boxi-rgb/brainrot-vault/reward.svg)

**Brainrot Vault** is a 3D "Steal a Brainrot"-style tycoon built for the
[make.fun roblox-brainrot-01 bounty](https://make.fun/bounty/roblox-brainrot-01).

## The game

Absurd meme characters — Captain Cucumber, DJ Fridge, King Kumquat, The Goosefather and ten
more — stroll down the central Brainrot Lane. Catch one, carry it home on your head (rarer
catches slow you down), and drop it on a pad in your own Vault, where it earns money every
second it stands there.

- **Rarity ladder:** Common → Rare → Epic → Legendary → Mythic, with Gold (×1.5),
  Diamond (×2.5) and Rainbow (×4) mutations rolled on every spawn.
- **Steal and defend:** another player's unguarded Vault is fair game — grab a placed
  brainrot and run. Lock your own Vault for 30 seconds to keep thieves out.
- **Tsunami:** every two minutes a wave sweeps the lane and washes away every brainrot
  still outside a Vault, carried ones included. Dash home or lose the catch.
- **Shop:** a rotating three-offer shop sells brainrots straight onto your free pads.
- **Rebirth:** pay an escalating cost to reset for a permanent +50% income multiplier
  and two extra pads per rebirth, up to ten pads.

## Layout

- `main.ts` — the hand-in program: copies `game.rbxl`, `src/`, `screenshots/` and
  `PLAY.json` to the output directory and writes `dossier.json` with the vendored
  make.fun library (`vendor/makefun-roblox.ts`, unchanged).
- `default.project.json` — the Rojo project: the static world (ground, lane, gates,
  eight base plots) plus the script folders.
- `src/shared/` — `BrainrotData` (the 14-character cast, rarities, mutations, prices)
  and `Config` (every tuning number), shared by server and client.
- `src/server/` — the game itself: `WorldBuilder` dresses the base plots,
  `CharacterFactory` builds each brainrot model, `Spawner` walks the lane,
  `Economy` owns player money, `Bases` handles pads, carrying, stealing and locks,
  `Shop` rolls offers, `Wave` runs the tsunami, and `Tour` stages the reviewer's
  screenshots.
- `src/client/Hud.client.luau` — the ScreenGui HUD: money, income, rebirth multiplier,
  shop panel, lock/rebirth buttons and event banners.

## Run it

Build the place with Rojo, then hand it in as the grader does:

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

## License

MIT — see `LICENSE`.
