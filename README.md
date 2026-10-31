# FORGE AFK - DAD MODE

**Azeroth can wait. Dad duty can't.**

A tiny, lighthearted World of Warcraft: Forever addon for players who have kids, partners, pets, doorbells and other unavoidable real-life raid bosses.

Made by **[Novyx Forge](https://wow.novyxforge.com/)**.

## Version

**0.1.1-alpha** - first playable build for WoW Forever beta (interface `16001`). In-game testing is still required.

## What it does

- Seven one-click reasons: **Kid Aggro**, **Partner Aggro**, **Pet Emergency**, **Toilet Raid**, **Phone Aggro**, **Snack Quest**, and **Doorbell Pull**.
- Sets your actual in-game AFK message using the modern `C_ChatInfo.SendChatMessage` API.
- Posts a short, fun message to **instance, raid or party chat** when you're grouped, when the client permits it. Does **not** broadcast to /say or /guild while solo.
- Starts a local elapsed-time timer that persists through `/reload`.
- **I'M BACK** clears your AFK message and sends a single return announcement to your current group.
- Small draggable dark-and-gold interface; window position saved between sessions.
- All messages are initiated by clicks or explicit slash commands. No anti-AFK automation and no background chat spam.

## Install (WoW Forever beta)

1. Download this repository as ZIP, then extract it.
2. Copy the inner **`ForgeAFK`** directory to:
   `World of Warcraft/_classic_beta_/Interface/AddOns/ForgeAFK/`
3. Check the folder contains `ForgeAFK.toc`, `Core.lua` and `UI.lua` directly, without another nested folder.
4. Fully restart the game. Check the addon is enabled in the AddOns menu.
5. Open the panel with **`/fafk`**. It also opens on the first install.

The beta client also recognises the `ForgeAFK_Forever.toc` variant. Both TOC files are included for ease of installation. The final release's interface version and install path may change.

## Slash commands

| Command | Action |
|---|---|
| `/fafk` | Toggle the panel |
| `/fafk kid` | Start Kid Aggro |
| `/fafk partner` | Start Partner Aggro |
| `/fafk pet` | Start Pet Emergency |
| `/fafk toilet` | Start Toilet Raid |
| `/fafk phone` | Start Phone Aggro |
| `/fafk snack` | Start Snack Quest |
| `/fafk doorbell` | Start Doorbell Pull |
| `/fafk back` | Return to Azeroth |
| `/fafk help` | Print command help |
| `/fafk about` | Novyx Forge website |

`/forgeafk` is an alias for `/fafk`.

## Test checklist

- [ ] Addon appears as **Forge AFK - Dad Mode** on the Forever beta AddOns screen.
- [ ] On first login, the window opens without Lua errors.
- [ ] `/fafk` toggles the window; dragging and `/reload` preserve position.
- [ ] All seven reasons update the AFK message and begin the timer.
- [ ] Solo mode does not post public chat.
- [ ] Party, raid and instance groups each use the appropriate group channel (subject to game chat restrictions).
- [ ] `I'M BACK` clears AFK and resets the timer.
- [ ] `/reload` during an active AFK session retains the timer.
- [ ] No errors or repeated chat sends in combat.

WoW's security and chat rules can restrict sending messages, especially in instances and during combat. The addon does not bypass those restrictions. Testing is required before a CurseForge release.

## Distribution

This repository is the source-code home. Public addon releases and updates will go through **CurseForge**. [Novyx Forge](https://novyxforge.com/) is the project showcase, not an alternative addon download host.

## License

MIT - see [LICENSE](../LICENSE).
