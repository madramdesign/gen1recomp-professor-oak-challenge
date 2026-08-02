# Professor Oak Challenge

A [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) mod for the classic **Professor Oak Challenge**: catch and fully evolve every reasonably available Pokémon before each gym.

## Features

- **Checklist** — Start menu → **OAK CHALLENGE** (progress for the next gym)
- **Soft gate** (default) — gym leaders warn if you’re incomplete; YES continues
- **Hard gate** — gym leaders refuse until the checklist is done
- **Off** — tracking only, no gym prompts
- Red + Blue exclusives (Yellow uses the Red table for now)
- Trade evolutions optional (Alakazam / Machamp / Golem / Gengar)
- Starter line, dojo Hitmon, Eevee, and fossil one-of rules

## Install

1. Download the release zip, or copy this folder to  
   `~/Library/Application Support/pokemon-love2d/mods/professor_oak_challenge/`
2. F10 → enable **Professor Oak Challenge**
3. Restart if needed

## Options (F10)

| Option | Default | Meaning |
| --- | --- | --- |
| GATE MODE | SOFT | Soft warn / Hard block / Off |
| REQUIRE TRADE EVOS | Off | Include trade-only finals |

## Notes

- Segment lists are **best-effort for v0.1** — soft mode won’t soft-lock you if a species is listed early/late.
- Ownership uses `pokedex.owned` (caught, gifted, or evolved).
- Don’t confuse with Nuzlocke — different challenge.

## License

MIT
