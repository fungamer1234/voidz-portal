# VOIDZ HUB — Portal Sandbox

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/fungamer1234/voidz-portal/main/VOIDZ_PORTAL.lua", true))()
```

Build `2026-10-29-1.6.12`

Game: [Portal Sandbox](https://www.roblox.com/games/75108253383447/Portal-Sandbox). PlaceId `75108253383447`.

## MacSploit

1. Join Portal Sandbox.
2. Paste the loadstring into MacSploit and execute it.
3. Press RightShift to hide or show VOIDZ HUB.

A copy of the same file is at `Documents/MacsploitUI/scripts/VOIDZ_PORTAL.lua` if you want to execute the local file instead.

## Tabs

Home lists every tab and the activity log. Click a row to open that tab. The open tab is marked in purple.

- **Move.** Fly, noclip, walk speed, infinite jump, click teleport, and anti void.
- **PvP.** Auto kill loops you a short distance behind the target and fires the weapon you have out. A selected player is the only target, and the script waits when they are gone. Mech escape spams space while a mech is holding you. Home when hurt teleports you to your house spawn under the health percent you set.
- **Materials.** Auto collect stands on ground scrap, fires the pickup, and stays until the game takes it, then moves to the next closest. It skips chairs. Choose a material to grab only that type.
- **Portals.** Refresh opens the dimension menu and lists the worlds it is showing, plus world pads in the map. Press one. The hub steps aside so the game receives that click, and a pad teleport is held in place. It does not cycle through worlds.
- **Visuals.** Client-side player highlights, fullbright, and field of view.
- **Players.** The list on the right selects a player. The selected card is purple and labeled SELECTED. Your own card says YOU and cannot be selected. Click a selected card again, or press Unselect, to clear it. Teleport, spectate, and auto kill use that player while their character is in the world, even if the health number reads 0.
- **Settings.** Unload script turns off every feature the hub enabled, restores your character, camera, lighting, and field of view, and removes the window.

The hub sends the game's own keys when a feature needs them: T portal gun, Q knife, E regenerate, F blender (press before you enter a portal), R dimensions, X laser or mech, V robo arms. These actions run in Portal Sandbox only. The hub does not spawn gear the game did not give you.

## Check

Luau 0.742 compiled this file at `-O0`. It has not been executed inside a live Portal Sandbox server.
