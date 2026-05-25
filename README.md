# SwayMovies

Movie-themed dotfiles for **Sway** on Fedora/Linux: one command switches wallpaper, colors, Waybar, Foot, Rofi, and fastfetch.

## Themes

| ID | Movie / style |
|----|----------------|
| `terminator` | Terminator / Skynet |
| `starwars` | Star Wars (dark) |
| `starwars-light` | Star Wars — Hoth / X-wing (light Foot) |
| `mandalorian` | The Mandalorian |
| `eighties` | Retro 80s room |
| `tmnt` | Teenage Mutant Ninja Turtles |
| `bttf` | Back to the Future Part III |
| `predator` | Predator — jungle |
| `mortalkombat` | Mortal Kombat |
| `bikermice` | Biker Mice from Mars |
| `knightrider` | Knight Rider — KITT dashboard |

## Requirements

- [Sway](https://github.com/swaywm/sway)
- [waybar](https://github.com/Alexays/Waybar)
- [foot](https://codeberg.org/dnkl/foot)
- [rofi](https://github.com/davatorium/rofi) (Wayland)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) (optional)
- `swaybg`, `notify-send`, ImageMagick (optional, for screenshots)

## Install

```bash
git clone https://github.com/YOUR_USER/SwayMovies.git
cd SwayMovies
./install.sh
```

Then edit `~/.config/sway/config` for your monitors (see `config/sway/config.example`), reload Sway:

```bash
swaymsg reload
```

Add wallpapers to `~/Pictures/Wallpapers/` (see [wallpapers/README.md](wallpapers/README.md)).

## Usage

| Action | Command |
|--------|---------|
| Theme menu | **Super+Shift+T** |
| List themes | `~/.config/theme-switch/theme-switch.sh list` |
| Apply theme | `~/.config/theme-switch/theme-switch.sh starwars` |
| Current theme | `~/.config/theme-switch/theme-switch.sh current` |

Open a **new Foot** window and shell after switching for terminal + fastfetch colors.

## Repository layout

```
theme-switch/          # switcher scripts + themes/*/ assets
config/sway/           # sway config.d snippets, wallpaper helpers
config/waybar/         # waybar config (style.css comes from active theme)
config/rofi/           # example rofi config
fastfetch/             # logo examples
wallpapers/            # manifest (images gitignored)
install.sh
```

Paths in theme files use `@HOME@`; the installer and `theme-switch.sh` expand it to your home directory.

## Updating from this repo

```bash
cd ~/Projects/SwayMovies   # or your clone path
git pull
./install.sh
```

## License

MIT — wallpapers are your own files; movie imagery is for personal desktop use.
