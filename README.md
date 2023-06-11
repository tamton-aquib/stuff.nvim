# Stuff.nvim

Some little plugin-like files put together.
> **Warning**
> 
>  Not much use, theres no config options, etc 
> (just wanted to share the work)

Feel free to extract and make any of them useful.

Included modules:

### Calc (<150 loc)
![calc](https://user-images.githubusercontent.com/77913442/183280043-b8e0b5bf-2fb3-41a8-b244-835743f1bdf3.gif)
```lua
require("calc").setup()
```

- Todo:
    - [ ] emulate keypress with highlights.
    - [ ] avoid hardcoded layout.
    - [ ] preset calculate yanked item.

---

### Stalk (< 50 loc)
![stalk](https://user-images.githubusercontent.com/77913442/183280315-56706519-1434-47a3-be45-5b3eeb5fa37b.gif)
```lua
require("stalk").setup()
```

- Todo:
    - [ ] add highlights, etc (cleanify)

---

### Scratch (< 50 loc)
![scratch_stuff](https://user-images.githubusercontent.com/77913442/183280873-986a68d0-ac3f-4dcc-97a5-6adc40035d05.gif)
```lua
require("scratch").setup()
```
---

### Bt (bookmark toggle <50 loc)
![bt](https://user-images.githubusercontent.com/77913442/183281125-8f7f03cd-58a9-44c0-a139-2f0f52a596de.gif)
```lua
require("bt").setup()
```
---

### Float (50 loc)  ❗Moved to [flirt.nvim](https://github.com/tamton-aquib/flirt.nvim)
![float](https://user-images.githubusercontent.com/77913442/183281327-eeafbd28-7287-4edd-a725-522280382b8d.gif)
```lua
require("float").setup()
```

---

### TmpClone (75 loc)
![tmpclone](https://user-images.githubusercontent.com/77913442/188803827-bc56d6d8-eae9-473b-b340-df4b5ba843d2.gif)
```lua
require("tmpclone").clone()
```

---

### Player (<150 loc) ❗Moved to [mpv.nvim](https://github.com/tamton-aquib/mpv.nvim)
![player](https://user-images.githubusercontent.com/77913442/206535745-e3e55f2a-99d9-418b-b2c4-b170a7615ccd.gif)
```lua
require("player").toggle_player()
```

## Other dev files (not completed):
- xkcd.lua - [XKCD](https://xkcd.com/) comics in neovim (needs [hologram.nvim](https://github.com/edluffy/hologram.nvim) 60LOC)
- chatgpt.lua - ChatGPT with limited features (24LOC)
- lazyn.lua - A plugin installer for [lazy.nvim](https://github.com/folke/lazy.nvim) (< 100LOC)
- rain.lua - Raining effect (might add to [zone.nvim](https://github.com/tamton-aquib/zone.nvim) later <50LOC)
- thunder.lua - rest client inspired from vscodes thunderclient. (Just have get function for now)
- neofetch.lua - system info using libuv
- snake.lua - snake game using floating wins
- cost.lua - [import-cost](https://github.com/wix/import-cost) alternative

## Inspiration
- `Scratch`: emacs-scratch-buffer + [shift-d](https://github.com/shift-d)
- `Calc`: [binx](https://github.com/BinxDot/)
- `Stalk`: [vim-github-dashboard](junegunn) + [dundargoc](https://github.com/dundargoc)
- `Float(flirt.nvim)`: [vsedov](https://github.com/vsedov) + [camspiers](https://github.com/camspiers/animate.vim) (moved)
- `TmpClone`: [Danielhp95](https://github.com/Danielhp95/tmpclone-nvim)
- overall thanks to [vhyrro](https://github.com/vhyrro).
