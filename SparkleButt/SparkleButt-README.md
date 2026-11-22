# SparkleButt 🐉

An emerald dragon companion for **WoW Forever** with StarfallTrail-powered navigation, mouseover unit inspection, quest-objective hints, and target range bands.

**[Read the complete SparkleButt guide](SparkleButt-Guide.html)** (open as a file or publish via GitHub Pages; GitHub's code viewer shows HTML source rather than rendering a webpage).

## Quick start

Install the `SparkleButt` addon alongside a compatible original StarfallTrail installation with the separate SparkleButt integration changes. Reload the game.

- `/sb auto` — automatically navigate or rest beside the player
- `/sb chase` — guide using the active route
- `/sb pet` — companion mode
- `/sb radar on` / `/sb radar off` — toggle mouseover inspector
- `/sb text` — cycle above/below/off target-range label
- `/sb snack` — snack interaction
- `/sb off` — turn off SparkleButt and SparkleRadar

**SparkleRadar:** hover over creatures or players to see names, level, class or creature type, reaction/class colors, and a yellow dot for readable unfinished quest objectives. Rare/elite alerts are implemented but the rare-spawn branch still awaits a real encounter test.

**Limitations:** target-distance values are range brackets, not exact measurements. World-object detection (herbs, mining, treasure) is not in this release. SparkleRadar is mouseover-based, not a background rare detector.

StarfallTrail belongs to its original creator. This repository intends to distribute our integration modifications, not replace the original StarfallTrail download.
