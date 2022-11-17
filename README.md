# Stuff.nvim

Some little plugin-like files put together.
> Warning:
Not much use, theres no config options, etc (just wanted to share the work)

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

### Float (50 loc)  ❗Moved to [flirt.nvim](https://github.com/flirt.nvim)
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

## Other dev files (not completed):
- neofetch.lua (system info using libuv)
- snake.lua (snake game using floating wins)
- animate.lua (animates closing windows, prolly add support later for opening)
- cost.lua ([import-cost](https://github.com/wix/import-cost) alternative)

## Inspiration
- `Scratch`: [shift-d](https://github.com/shift-d)
- `Calc`: [binx](https://github.com/BinxDot/)
- `Stalk`: [dundargoc](https://github.com/dundargoc)
- `Float`: [vsedov](https://github.com/vsedov) (moved)
- `TmpClone`: [Danielhp95](https://github.com/Danielhp95/tmpclone-nvim)
- `animate`: [camspiers](https://github.com/camspiers/animate.vim)
