<div align="center">

# SparkleButt 🐉

### Seven surprisingly capable magical traveling companions.

**Quest navigation · Seven companion looks · Live 3D wardrobe · SparkleRadar · Combat Panel · SparkleBag · SparkleWand · Custom waypoints · Snack Heart**

*An accessibility-minded companion addon built for WoW Forever, powered by StarfallTrail navigation.*

**Current build:** v0.6.57 (Combat Panel + Radar deduplication test) · **WoW Forever interface:** 16001

</div>

---

## Meet your new co-pilot

SparkleButt is a small animated magical companion that stays with your character, helps guide you along quest routes, and makes it easier to identify the creatures around you without clicking through every target. Choose from dragon whelps, a Wisp, or a Sprite Darter. Your companion even comes down for a snack.

### What your companion can do

| 🧭 **Find your way** | 🐉 **Stay by your side** |
|:---|:---|
| **Auto** follows StarfallTrail navigation and settles beside you when you arrive. **Chase** actively follows a route. | **Pet** keeps SparkleButt nearby. He animates between positions instead of abruptly teleporting. |
| 🔎 **SparkleRadar** | 🎯 **Target range** |
| Sweep your mouse over players and creatures to print readable, color-coded information in chat—no click needed. | Shows simple target-distance **range bands** beside SparkleButt in Pet position (for example, `10 yd`, `20 yd`, `30 yd`, `> 30 yd`). |
| 📍 **Go wherever you want** | 🟡 **Quest hints** |
| **Alt + left-click** anywhere on your world map to set a custom destination. SparkleButt leads you there, then returns to your quest route. | A yellow quest indicator flags mouseover creatures with **readable, unfinished** quest objectives. |
| 💚 **A bit of personality** | ✨ **A smooth little flyer** |
| Click the **hollow pink heart above the wardrobe button** or use `/sb snack` to give SparkleButt a treat. The heart fills during the snack animation, then becomes hollow again. | SparkleButt flies between guiding and Pet positions rather than abruptly teleporting. |
| 🪙 **SparkleBag** | 💜 **SparkleWand** |
| Open your bank and press the silver SparkleBag control **once** to deposit matching items from your backpack and equipped bags. | Enable the **plum-purple SparkleWand control** for right-click wand shooting on hostile mouseover targets. Turn it off to restore ordinary right-click behavior. |
| 💬 **Player interactions** | ⚔️ **Combat Panel** |
| Right-click a player name printed by SparkleRadar to open the game’s native player menu. Full-name whispers are supported. | Optional, movable health-bar rows for engaged enemies exposed by the game client; highlights your current target. |

### Meet the companion wardrobe

**Seven appearances, one familiar companion system.** Open the full wardrobe with `/sb wardrobe`, where you can select a look and see a **live, front-facing 3D model preview** with a matching glow effect. Your selected look is saved for future sessions.

| Companion | Appearance and aura |
|:---|:---|
| 🟢 **Emerald Whelp** | The original little green dragon and green glow |
| 🔴 **Crimson Whelp** | Red dragon with a vivid red glow |
| 🔵 **Azure Whelp** | Blue dragon with a stronger, cool azure glow |
| ⚫ **Dark Whelp** | Dark dragon with warm orange glow |
| 🟤 **Bronze Whelp** | Bronze-colored dragon with light golden glow |
| 🔹 **Wisp** | Bright magical spirit with **natural model illumination**; the model is especially luminous |
| 🌸 **Sprite Darter** | Colorful faerie dragon with pink glow |

The small **color-changing wardrobe button above Auto** cycles through these looks in that exact order and returns to Emerald after Sprite Darter. Its indicator colors are deliberately separate from the glow colors. The wardrobe preview is a helpful approximation; real-world lighting may differ from the preview window.

**Wardrobe status:** All seven model choices and the 3D preview were tested visually in WoW Forever in v0.6.45. The Wisp remains much brighter than the other models due to its native illumination.

> **Rare & elite alerts:** Special alerts are implemented, but the rare-spawn alert has not yet been verified in a live encounter.

## Eleven compact controls

| Control | What it does |
|:---|:---|
| ❤️ **Snack Heart** | Above the wardrobe: click the hollow heart to feed your companion; it fills briefly during the animation |
| 🌈 **Wardrobe** | Cycle all seven companion looks; button color shows your current selection. Use `/sb wardrobe` for the full 3D preview menu |
| 🔵 **Auto** | Navigate automatically; return to Pet position at the destination |
| 🟢 **Chase** | Follow the current navigation route |
| 🟡 **Pet** | Stay next to your character |
| 📏 **Target Range** | Cycle the range label **Above → Below → Off** |
| 🟠 **SparkleRadar** | Switch mouseover identification on or off independently |
| ⚫ **Off** | Turn off both SparkleButt and SparkleRadar |
| 💜 **SparkleWand** | Plum-purple toggle; enables or disables right-click wand shooting for wand-equipped classes |
| 🟥 **Panel** | Gray square when off, dark red when on; enables combat-only enemy health rows |
| ⚪ **SparkleBag** | While your personal bank is open, deposit inventory items whose item types were already in your bank |

## Your adventure, your destination: custom waypoints 📍

Questing is only part of the journey. Want to visit a town, stop at a merchant, or explore somewhere off the planned route? **Open the world map, hold Alt, and left-click your destination.** SparkleButt temporarily follows your custom waypoint instead of the active quest route.

When you arrive, the custom waypoint clears and **normal quest navigation resumes**. Want to change your mind along the way? Type `/sb clear` to cancel the waypoint and return to quest navigation.

You can also enter a location manually with `/sb waypoint MAPID X Y` (map ID and percentage coordinates). The feature requires the included **StarfallTrail integration changes**; the unmodified StarfallTrail addon alone does not provide this custom-waypoint bridge.

## SparkleBag: one-click bank deposits 🪙

Open your **personal bank** and click the **silver SparkleBag control**, immediately below **Off** in SparkleButt’s selector. SparkleBag checks your bank, then automatically tries to deposit matching items from your **backpack and bags 1–4**, one stack at a time, from a single button press.

**Only item types already stored in the bank when you press the button qualify.** Unmatched inventory items stay in your bags. SparkleBag uses existing bank stacks or available bank slots as the game permits, and stops quietly when no more eligible transfers remain. It also stops if the bank closes or an item fails to leave inventory.

**Test status:** Multiple matching stacks were successfully deposited with one click in WoW Forever using v0.6.37. This is a newly tested feature; please report unusual banking behavior. SparkleBag does not automatically run merely because you open the bank.

## SparkleWand: right-click wand shooting 💜

The **plum-purple control immediately below SparkleBag** toggles SparkleWand independently from SparkleButt’s navigation modes. When enabled and a wand is equipped, **right-clicking a hostile mouseover target initiates the wand’s Shoot attack** instead of the normal melee right-click. It is intended for wand-using **Mages, Priests, and Warlocks**. A dim plum button indicates the feature is off; your on/off choice is saved between sessions.

**Combat behavior:** In-game testing of v0.6.46 confirmed that SparkleWand works, including the spell-interruption scenario that motivated its development. The addon uses secure bindings, so **changing the toggle during combat may not take effect until combat ends**. The actual wand attack still depends on game mechanics, range, and having a usable wand equipped.

**Important:** Disable or remove **AutoWand** (and other addons that override right-click / `BUTTON2`) before using SparkleWand. They can conflict with the same right-click binding.

## Snack Heart: a treat in one click ❤️

The **small hollow pink heart above the wardrobe color button** triggers the existing companion snack animation. Click once to give SparkleButt a treat and enjoy the accompanying hearts and chat reactions. The heart fills while the animation plays, then returns to a hollow outline so you can feed him again. Your companion needs to be enabled for snacks. The original `/sb snack` command still works.

## Combat Panel: engaged enemies at a glance ⚔️

**New in v0.6.51–v0.6.57.** Click the small **Panel** square in SparkleButt’s selector to enable a compact, combat-only display of enemy names, levels (when available), and health bars. **Gray = off; dark red = on.** The panel is **off by default** and its enabled state is saved. It has no permanent background tray during normal use.

- **Nameplate-first collection:** the panel uses visible nameplate units to represent distinct enemies. v0.6.57 prioritizes those units to avoid duplicate rows caused by overlapping target and party-target references.
- **Conservative fallback:** when no qualifying nameplates are visible, it can show a single eligible target or party/raid target rather than risking duplicated enemies.
- **Current-target highlight:** a gold border identifies your selected target when the client exposes enough information to match it.
- **Display only:** rows do not target enemies or perform combat actions. Health bars use native WoW status bars to handle protected health values.
- **Movable and persistent:** use `/sb panel` to show positioning mode, drag the panel, then type `/sb panel` again. Its location persists across sessions.

**Diagnostics:** `/sb panel status` prints the panel's enabled/combat/positioning state and available enemy count. `/sb panel test` toggles **three synthetic enemy rows** for layout testing without combat. Turn test mode off again before normal use.

**Known limits:** the game only exposes some nearby units. Enemies with no visible nameplate or accessible target token may not appear; combat and health information can be restricted. **A successful deduplication test does not establish complete enemy detection.** SparkleRadar itself may not behave as expected in dungeons; dungeon Radar coverage is not verified for this build. The v0.6.57 ZIP is labeled **TEST** and should be validated in WoW Forever before being called a stable release.

## SparkleRadar, at a glance

Hover over a character or creature and SparkleButt can print its name, level (`Lv`), and available type/class information. Players use familiar WoW class colors; hostile and friendly creatures use reaction coloring. Different creatures with the same name are tracked separately where unit GUIDs are available.

**Quest objective?** A yellow indicator appears before the name when an unfinished objective is readable. **Quest already complete?** No quest indicator.

**Player interaction:** Right-click a player’s name in a SparkleRadar chat message to open WoW Forever’s normal player interaction menu. Choose **Whisper** to address the full displayed player name. Player menus and full-name whispers have been verified in game.

**Creatures:** Creature names are informational rather than clickable menu links. The native creature menu required a currently targeted creature in testing, so the experimental chat-menu feature was removed.

Radar **does not** automatically scan the world for nearby rare spawns: it identifies units you actually mouse over.

## Prerequisites

Install all three dependencies before using SparkleButt's quest navigation:

- **Questie** — provides quest tracking data for the navigation workflow.
- **QuestieDB** — **required library** for the Questie-based quest data functionality. Install it alongside Questie.
- **StarfallTrail** — provides route navigation for SparkleButt. Download the original from PXPerfect Mike and apply the separately provided SparkleButt integration changes.

## Getting started

1. Install **Questie**, **QuestieDB**, and the **original StarfallTrail** from its creator; apply the separately provided SparkleButt integration changes.
2. Place `SparkleButt` in your WoW Forever `Interface/AddOns` directory.
3. Reload the game (`/reload`) and use the in-game selector or commands below. The **Snack Heart** sits above the wardrobe cycle button; the wardrobe button sits above **Auto**. The selector also includes the plum-purple **SparkleWand** toggle, the gray/dark-red **Panel** square, and the silver **SparkleBag** button. SparkleBag requires an open personal bank.

```text
/sb wardrobe             Open the seven-companion 3D preview menu
/sb look azure           Select a look by name (e.g., emerald, crimson, azure)
/sb auto                 Automatic navigation
/sb chase                Follow the current route
/sb pet                  Stay beside the player
/sb petside left         Place Pet on the left
/sb petside right        Place Pet on the right
/sb radar on             Enable mouseover identification
/sb radar off            Disable mouseover identification
/sb panel                Toggle Combat Panel positioning and dragging
/sb panel status         Print Combat Panel diagnostic status
/sb panel test           Toggle three synthetic test rows
/sb text                 Cycle target-range text position
/sb waypoint MAPID X Y   Set a custom destination by coordinates
/sb clear                Cancel a custom waypoint
/sb snack                Give SparkleButt a snack
/sb off                  Disable dragon and Radar
/sb status               Show current settings
```

## Good to know

- **Wardrobe preview uses an in-game model frame:** colors and light levels can look different from the flying companion in the world.
- **Target range is approximate:** labels indicate tested range thresholds, **not exact yards**.
- **Mouseover-only Radar:** players and creatures are supported; herb, mining, and chest identification is **not included** in this release. Dungeon behavior still needs verification.
- **SparkleWand:** Disable AutoWand and other conflicting right-click binding addons; combat lockdown defers toggle binding updates until combat ends.
- **Snack Heart:** Requires an active companion, and `/sb snack` remains available.
- **Combat Panel:** Off by default; only exposes enemies reported by available client unit tokens and nameplates. Use `/sb panel test` for layout diagnosis. v0.6.57 is a test build.
- **StarfallTrail is required.** Our integration allows navigation calculations to continue when its visible ground trail is turned off and supplies the custom-waypoint bridge.
- **SparkleBag requires an open personal bank** and available bank capacity; it will not deposit item types absent from the bank at the start of the action.
- **Treasure Nose is shelved:** no autonomous gathering-node tracking is claimed.
- Earlier builds were field-tested for navigation, Radar, player interaction menus, full-name whispers, one-click SparkleBag deposits, all seven companion models, the wardrobe preview, the Snack Heart, and SparkleWand right-click attacks. v0.6.57 includes an in-progress Combat Panel with nameplate-first deduplication; complete in-game validation remains outstanding. Rare-spawn alerts also still need verification.

## Credits & collaboration

**Created by Santa Nicholas with Murphy** through iterative design and in-game testing.

**StarfallTrail** is an independent addon by **PXPerfect Mike**. SparkleButt uses it for navigation and provides integration changes for custom waypoints and invisible-route operation. The supplied v0.6.57 test ZIP contains both `SparkleButt/` and a `StarfallTrail/` directory with integration files; when publishing, preserve the original author’s attribution and check distribution permissions. Users can obtain StarfallTrail from its original creator and apply the integration changes.

Feedback, bug reports, and code review are welcome—especially from **PXPerfect Mike**.

---

<div align="center"><strong>Built for adventures, little discoveries, and the occasional snack. 💚</strong></div>
