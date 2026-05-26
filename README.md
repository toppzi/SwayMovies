# SwayMovies

Movie-themed dotfiles for **Sway** on Fedora/Linux: one command switches wallpaper, colors, Waybar, Kitty, Rofi, and fastfetch.

## Themes

| ID | Movie / style |
|----|----------------|
| `terminator` | Terminator / Skynet |
| `starwars` | Star Wars (dark) |
| `starwars-light` | Star Wars — Hoth / X-wing (light palette) |
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
- [kitty](https://sw.kovidgoyal.net/kitty/)
- [rofi](https://github.com/davatorium/rofi) (Wayland)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) (optional)
- `swaybg`, `notify-send`, ImageMagick (optional, for screenshots)
- `mate-polkit` (recommended on Fedora 41+, for privilege prompts in Sway; replaces removed `polkit-gnome`)
- `xorg-x11-server-utils` (provides `xrandr`; **required** for Lutris to start on Wayland)
- `NetworkManager-applet` (optional tray icon; `nm-applet`)
- `sddm` (optional, for themed login screen sync via `sddm-sync.sh`)

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
| Firefox (Media ws) | **Super+B** |
| Thunar (Main ws) | **Super+Shift+F** |
| Vesktop (Chat ws) | **Super+Shift+D** |
| Steam (Games ws) | **Super+G** |
| Apply theme | `~/.config/theme-switch/theme-switch.sh starwars` |
| Current theme | `~/.config/theme-switch/theme-switch.sh current` |
| Login theme | Restored automatically on Sway start from `~/.local/state/theme-switch/current` |
| Sync SDDM login background | `sudo ~/.config/theme-switch/sddm-sync.sh` |

Open a **new Kitty** window after switching for terminal + fastfetch colors (running Kitty windows update colors automatically when possible).

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
