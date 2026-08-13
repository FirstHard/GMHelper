# GMHelper — Guildmaster's Helper

**GMHelper** is a World of Warcraft 3.3.5a addon designed for more convenient guild management.

It provides a modern interface for browsing, filtering members, selecting multiple characters, and performing administrative actions based on the current character's guild permissions.

---

## Features

### Guild Roster

- full guild member list;
- character, level, rank and note information;
- last-online information;
- sortable columns;
- officer note visibility based on the current character's permissions;
- automatic roster and online-status updates.

### Filters

- minimum level;
- maximum level;
- offline duration threshold in days or months;
- **All Members / Online Only** mode;
- one-click filter reset.

### Member Selection

- select individual characters;
- select all characters matching the current filters;
- keep selections while the roster is refreshed;
- display the number of selected members.

### Guild Management

- mass removal of selected members;
- confirmation dialog before mass removal;
- queued removal with a short delay between operations;
- rank promotion and demotion;
- changing the rank of one or multiple selected members;
- rank selection directly inside the **Rank** column;
- actions are available only when the current character has the required permissions.

### Notes

- edit a single member's public note;
- edit a single member's officer note;
- editing is available only when the current character has the appropriate permission;
- mass note editing is intentionally not included.

### Interface

- modern compact window;
- translucent interface;
- movable main window;
- saved window position;
- separate movable addon button;
- closes with `Esc`;
- automatically hides when the WoW main menu opens;
- custom scrollbar.

---

## How to Use

### Launching

After entering the game, click the **GMHelper** button or use:

```text
/gmhelper
```

Short aliases are also available:

```text
/gmh
/gm
```

### Filtering

Use the controls at the top of the window to set:

- minimum level;
- maximum level;
- minimum offline duration;
- time unit — **months** or **days**;
- **All Members / Online Only** mode.

The roster updates automatically when the filter changes.

Use **Reset** to clear all filters.

### Selecting Members

Use the checkbox to the left of a character's name.

The checkbox in the first column header selects or deselects all members currently matching the active filters.

### Changing Rank

When the current character has the required permissions, the **Rank** column provides the available rank options.

When several members are selected, choosing a new rank for one compatible member can apply the same rank change to all compatible selected members.

A confirmation dialog is shown before the operation is executed.

### Removing Members

Select one or more members and press:

```text
Remove selected
```

Before the operation starts, GMHelper displays a confirmation dialog containing the number of selected members and the active filter conditions.

---

## Installation

1. Download the [latest GMHelper release](https://github.com/YOUR-USERNAME/GMHelper/releases/latest).
2. Extract the archive.
3. Place the `GMHelper` folder into:

```text
World of Warcraft/Interface/AddOns/
```

The final structure should be:

```text
World of Warcraft/
└── Interface/
    └── AddOns/
        └── GMHelper/
            ├── GMHelper.toc
            ├── Core.lua
            ├── Permissions.lua
            ├── Debug.lua
            └── UI.lua
```

4. Launch the game and make sure **GMHelper** is enabled in the AddOns list.

---

## Updating

It is recommended to close the game before updating.

1. Download the latest release.
2. Remove the old `GMHelper` folder.
3. Extract the new `GMHelper` folder into `Interface/AddOns/`.
4. Start the game.

Addon settings are stored in `SavedVariables` and are preserved between updates.

---

## Compatibility

GMHelper is developed for:

- **World of Warcraft 3.3.5a**
- client interface version **30300**

API behavior may vary between different 3.3.5a-based game projects and client builds.

---

## Suggestions and Contributions

Ideas, bug reports, UI suggestions, feature requests, and improvements are welcome.

Please use GitHub Issues for:

- bug reports;
- UI suggestions;
- feature requests;
- discussions about improvements.

**Repository:**  
`https://github.com/YOUR-USERNAME/GMHelper`

When reporting a problem, please include:

- GMHelper version;
- client version/build;
- a description of the problem;
- steps to reproduce it;
- the Lua error text, if available.

Pull Requests with improvements are also welcome.

---

## Donations

GMHelper is free to use.

If you find the addon useful and would like to support its development, you can make a voluntary donation through one of the services below:

- **DonationAlerts:** [dalink.to/phoenixnest](https://dalink.to/phoenixnest)
- **Buy Me a Coffee:** [buymeacoffee.com/TekhnoKhobbIT](https://buymeacoffee.com/TekhnoKhobbIT)
- **Donatello:** [donatello.to/TekhnoKhobbIT](https://donatello.to/TekhnoKhobbIT)

Donations are completely voluntary and do not provide additional in-game features or advantages.

---

## License

Unless stated otherwise in the repository, the use and distribution of GMHelper are governed by the license provided in the project repository.

---

## Thanks

Thank you to everyone who tests GMHelper, reports bugs, and suggests improvements.

**GMHelper — Guildmaster's Helper**
