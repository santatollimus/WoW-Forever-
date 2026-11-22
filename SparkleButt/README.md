<div align="center">

# SparkleButt 🐉

### Seven surprisingly capable magical traveling companion.

**Quest navigation · Seven companion looks · Live 3D wardrobe · SparkleRadar · SparkleBag · Custom waypoints · Snacks**

*An accessibility-minded companion addon built for WoW Forever, powered by StarfallTrail navigation.*

**Current build:** v0.6.45 (Wardrobe Preview test build) · **WoW Forever interface:** 16001

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
| Give him a snack with `/sb snack` and watch his little animation. | SparkleButt flies between guiding and Pet positions rather than abruptly teleporting. |
| 🪙 **SparkleBag** | 💬 **Player interactions** |
| Open your bank and press the silver SparkleBag control **once** to deposit matching items from your backpack and equipped bags. | Right-click a player name printed by SparkleRadar to open the game’s native player menu. Full-name whispers are supported. |

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

## Eight simple controls

| Control | What it does |
|:---|:---|
| 🌈 **Wardrobe** | Cycle all seven companion looks; button color shows your current selection. Use `/sb wardrobe` for the full 3D preview menu |
| 🔵 **Auto** | Navigate automatically; return to Pet position at the destination |
| 🟢 **Chase** | Follow the current navigation route |
| 🟡 **Pet** | Stay next to your character |
| 📏 **Target Range** | Cycle the range label **Above → Below → Off** |
| 🟠 **SparkleRadar** | Switch mouseover identification on or off independently |
| ⚫ **Off** | Turn off both SparkleButt and SparkleRadar |
| ⚪ **SparkleBag** | While your personal bank is open, deposit inventory items whose item types were already in your bank |

## Your adventure, your destination: custom waypoints 📍

Questing is only part of the journey. Want to visit a town, stop at a merchant, or explore somewhere off the planned route? **Open the world map, hold Alt, and left-click your destination.** SparkleButt temporarily follows your custom waypoint instead of the active quest route.

When you arrive, the custom waypoint clears and **normal quest navigation resumes**. Want to change your mind along the way? Type `/sb clear` to cancel the waypoint and return to quest navigation.

You can also enter a location manually with `/sb waypoint MAPID X Y` (map ID and percentage coordinates). The feature requires the included **StarfallTrail integration changes**; the unmodified StarfallTrail addon alone does not provide this custom-waypoint bridge.

## SparkleBag: one-click bank deposits 🪙

Open your **personal bank** and click the **silver SparkleBag control**, immediately below **Off** in SparkleButt’s selector. SparkleBag checks your bank, then automatically tries to deposit matching items from your **backpack and bags 1–4**, one stack at a time, from a single button press.

**Only item types already stored in the bank when you press the button qualify.** Unmatched inventory items stay in your bags. SparkleBag uses existing bank stacks or available bank slots as the game permits, and stops quietly when no more eligible transfers remain. It also stops if the bank closes or an item fails to leave inventory.

**Test status:** Multiple matching stacks were successfully deposited with one click in WoW Forever using v0.6.37. This is a newly tested feature; please report unusual banking behavior. SparkleBag does not automatically run merely because you open the bank.

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
3. Reload the game (`/reload`) and use the in-game selector or commands below. The wardrobe cycle button is **above Auto**; the silver **SparkleBag** button is beneath **Off** and requires an open bank.

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
- **Mouseover-only Radar:** players and creatures are supported; herb, mining, and chest identification is **not included** in this release.
- **StarfallTrail is required.** Our integration allows navigation calculations to continue when its visible ground trail is turned off and supplies the custom-waypoint bridge.
- **SparkleBag requires an open personal bank** and available bank capacity; it will not deposit item types absent from the bank at the start of the action.
- **Treasure Nose is shelved:** no autonomous gathering-node tracking is claimed.
- The current version has been field-tested for navigation, Radar, player interaction menus, full-name whispers, one-click SparkleBag deposits, all seven companion models, and the wardrobe preview; rare-spawn alerts still need verification.

## Credits & collaboration

**Created by Santa Nicholas with Murphy** through iterative design and in-game testing.

**StarfallTrail** is an independent addon belonging to its original author. This project provides *integration changes*, not an alternative distribution of StarfallTrail. Please obtain the original addon from its creator.

Feedback, bug reports, and code review are welcome—especially from **PXPerfect Mike**.

---

<div align="center"><strong>Built for adventures, little discoveries, and the occasional snack. 💚</strong></div>
