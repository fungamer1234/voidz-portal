# VOIDZ HUB — Portal Sandbox

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/fungamer1234/voidz-portal/main/VOIDZ_PORTAL.lua", true))()
```

Build `2026-10-29-1.6.35`

Game: [Portal Sandbox](https://www.roblox.com/games/75108253383447/Portal-Sandbox). PlaceId `75108253383447`.

## MacSploit

1. Join Portal Sandbox.
2. Paste the loadstring into MacSploit and execute it.
3. A small picture button opens and closes VOIDZ HUB. Drag it anywhere. RightShift does the same.

A copy of the same file is at `Documents/MacsploitUI/scripts/VOIDZ_PORTAL.lua` if you want to execute the local file instead.

## Tabs

Home lists every tab and the activity log. Click a row to open that tab. The open tab uses the theme color. The normal theme is the green Rick and Morty portal, Rick in the swirl, and the intro song. Settings can turn on Evil Morty, which uses the gold gradient, your Evil Morty photo in the portal, and that song, or Soulja Boy, which changes the song only. Turning a theme off returns the green portal, Rick, and the intro. Music off silences every track. Those choices are saved and come back the next time you execute. The songs loop, and closing the hub pauses the current one. The pictures and tracks are loaded from `Documents/Macsploit Workspace/voidz-portal/`.

- **Move.** Fly, noclip, walk speed, infinite jump, click teleport, and anti void. Minus toggles fly. Walk speed moves you at the number you set, because the game was ignoring the normal walk value. It stays off while fly, auto kill, a teleport, or a mech grab is active. The hub scales open and closed, pages slide in, and toggles slide when you turn them on or off.
- **Teleport.** Home base is the house you spawned at. You can also save a mark, jump forward, jump up, jump to a random nearby spot, or teleport to the selected player or a random player. These stay in the current world.
- **PvP.** Auto kill keeps teleporting you behind the player, including when they turn or move their body in first person, and turns you to face them until you turn it off. Your crosshair stays on that player so you can shoot. The mouse pointer still reaches the hub, and you can zoom, including first person. Auto fire is a separate toggle that shoots the weapon in your hand. A selected player is the only target, and the script waits when they are gone. Keep away steps you back when another player gets inside the range, 15 studs by default. It pauses during auto kill, fly, and material pickup. Mech escape keeps tapping space while a grab or slam is holding you, and stops once you are free. It does not hold jump. Home when hurt teleports you to your house spawn under the health percent you set.
- **Materials.** Auto collect stands on ground scrap, fires the pickup, and stays until the game takes it, then moves to the next closest. It skips chairs. Choose a material to grab only that type. Zone route instantly teleports you onto each material area, takes at most 10, then teleports straight to the next area. It does not use the portal gun or the dimension menu.
- **Visuals.** Client-side player highlights, fullbright, and field of view.
- **Players.** The list on the right selects a player. The selected card uses the theme color and is labeled SELECTED. Your own card says YOU and cannot be selected. Click a selected card again, or press Unselect, to clear it. Teleport, spectate, and auto kill use that player while their character is in the world, even if the health number reads 0. Teleport follows their torso instead of a one-time jump.
- **Settings.** Keybinds cover fly, walk speed, auto collect, zone route, and keep away. Minus is fly until you change it. Unload script turns off every feature the hub enabled, restores your character, camera, lighting, and field of view, and removes the window.

The hub sends the game's own keys when a feature needs them: T portal gun, Q knife, E regenerate, F blender (press before you enter a portal), R dimensions, X laser or mech, V robo arms. These actions run in Portal Sandbox only. The hub does not spawn gear the game did not give you.

## Check

Luau 0.742 compiled this file at `-O0`. It has not been executed inside a live Portal Sandbox server.
