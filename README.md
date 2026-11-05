# FORGE AFK - DAD MODE

**Azeroth can wait. Dad duty can't.**

A lightweight, deliberately ridiculous **World of Warcraft: Forever** addon for busy dads, gamers and every parent interrupted by a real-life boss fight. Made by **[Novyx Forge](https://wow.novyxforge.com/)**.

**Current version: v1.0.1 — Release.** WoW Forever players have successfully verified the native AFK whisper replies and the new `/afk` menu shortcut in-game. Remaining optional behavior can be validated through continued player feedback.

## Your 12 real-life boss fights

| Button | Slash command | Comeback |
| --- | --- | --- |
| Kid Aggro | /fafk kid | Dad survived Kid Aggro. Bedtime boss defeated. |
| Partner Aggro | /fafk partner | Partner raid cleared. Relationship reputation +10. |
| Pet Emergency | /fafk pet | Pet escort quest complete. Paw patrol survived. |
| Toilet Raid | /fafk toilet | Dad survived the Toilet Raid. No loot dropped. |
| Phone Aggro | /fafk phone | Phone boss defeated. Battery -5. Sanity -20. |
| Snack Quest | /fafk snack | Snack quest complete. Inventory replenished. |
| Doorbell Pull | /fafk doorbell | Doorbell boss handled. Unexpected NPC despawned. |
| Sleep Debuff | /fafk sleep | Sleep debuff dispelled. Dad is operational. |
| Work Aggro | /fafk work | Work aggro evaded. Back to the real endgame. |
| Coffee Refill | /fafk coffee | Coffee potion consumed. Mana restored +100. |
| Delivery Boss | /fafk delivery | Delivery boss down. Package looted. |
| Dad Tech Support | /fafk tech | Wi-Fi boss defeated. Family reputation restored +100. |

Every reason starts an AFK timer and sets an in-game AFK message. When grouped and not silent, the addon attempts one group announcement. The **I'M BACK** button clears AFK and attempts a reason-specific comeback including elapsed time.

## Automatic whisper replies (native WoW feature)

**Yes!** When you click one of the twelve AFK reasons, Forge AFK sets WoW's real AFK status with a custom, branded message. WoW itself automatically responds to incoming **in-game whispers** with that message while you are flagged AFK. No separate whisper listener is needed.

For example, after choosing **TOILET RAID**, a whisper will receive this native AFK reply:

> [Forge AFK] TOILET RAID! Nature called a ready check. Dad is fighting a real-life boss. BRB!

Each AFK reason has its own one-line reply. Press **I'M BACK** to clear your native AFK status and its reply.

**Silent Mode only mutes outgoing party/raid/instance announcements.** It intentionally does not disable the game's automatic AFK response to incoming whispers.

Important: a game setting that automatically clears AFK when you move or perform an action can end the native auto-reply, even if the addon timer is still running. Battle.net whispers may behave differently. WoW Forever in-game whisper behavior needs to be verified during live testing.

## Features

- **12 large, one-click buttons**, displayed as a compact 2 × 6 grid.
- **Minimap button**: left-click opens/closes, right-click toggles Silent Mode, drag moves around the minimap; angle saved.
- **Silent Mode**: no party, raid or instance messages. Still sets a WoW AFK message. When enabled during an existing session it also suppresses the comeback.
- **Group-aware messages**: PARTY, RAID or INSTANCE_CHAT when applicable; no /say or guild spam.
- **Return button**: one unique reason-specific comeback, only if the session actually announced its departure and silent mode is off.
- **Native whisper auto-replies**: one branded message per reason, sent automatically by WoW when AFK.
- **Reload-safe timer**, SavedVariables settings and draggable window position.
- No external libraries, browser access, tracking or background activity. This is not an anti-AFK addon.

## Installation

The target is WoW Forever, using interface version **16001**.

1. Install via CurseForge once the Release file has been approved and published; for manual installation, extract the release ZIP.
2. Copy only the **ForgeAFK** directory from the extracted folder into your WoW Forever client's \`Interface/AddOns/\` directory, so the full path ends in \`Interface/AddOns/ForgeAFK/\`.
3. Verify that \`ForgeAFK.toc\`, \`ForgeAFK_Forever.toc\`, \`Core.lua\`, \`UI.lua\` and \`Minimap.lua\` are directly inside that folder, with no extra nested folder.
4. Restart WoW and enable **Forge AFK - Dad Mode** in the AddOns list.
5. Type \`/fafk\`. The window also opens on first login.

Both regular and Forever-style TOC filenames are included; which one the client reads depends on its addon loader.

## Commands

| Command | Description |
| --- | --- |
| \`/fafk\` | Toggle the addon window |
| \`/fafk <reason>\` | Start any reason key from the table above, e.g. \`/fafk tech\` |
| \`/fafk back\` | Finish AFK and return |
| \`/fafk silent\` | Toggle Silent Mode |
| \`/fafk minimap\` | Show or hide minimap icon |
| \`/fafk help\` | Show help in chat |
| \`/fafk about\` | Visit Novyx Forge |
| \`/forgeafk\` | Alias for \`/fafk\` |

### Example

**Party departure:** \`[Forge AFK] Toilet raid! Nature called a ready check. BRB.\`

**Comeback:** \`[Forge AFK] Dad survived the Toilet Raid. No loot dropped. Back after 06:42!\`

## Testing

Run \`lua5.1 tests/smoke.lua\` from the repo root. The GitHub workflow also runs Lua syntax checks and mocks the game's UI/chat functions. These tests **cannot replace live client testing**.

The in-game acceptance checklist:

- [x] Addon loads and displays 12 buttons in WoW Forever.
- [ ] \`/fafk\` opens/closes the panel and buttons set the actual AFK status.
- [ ] Timer works and survives \`/reload\`.
- [ ] Each departure/callback uses its matching joke and elapsed time.
- [ ] Silent Mode prevents all group announcements, including comebacks.
- [ ] No group chat traffic while solo.
- [ ] Party/raid/instance chat modes work under Forever's chat restrictions.
- [x] Have a second player whisper while AFK; the native reply with the themed WORK AGGRO text was confirmed in-game.
- [ ] Repeat with **Silent Mode** on: no group announcement but native AFK whisper reply still appears.
- [ ] Press **I'M BACK** and confirm the custom reply stops.
- [ ] Minimap left/right click, drag and hide/restore work.
- [ ] No errors during combat, logout, reload, or low resolution.

## Distribution

**GitHub** is the source code repository. Public addon downloads and updates are distributed **only through CurseForge** after its Release upload is approved. The [Novyx Forge](https://wow.novyxforge.com/) website is the showcase and documentation hub.

## License

MIT. See [LICENSE](LICENSE).
