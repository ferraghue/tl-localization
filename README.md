# TL Localization — English Translation for Astrum

English localization mod for the Astrum (RU) version of Throne and Liberty.  
Coverage: **135,010 / 138,748 lines** translated.

---

## Installation

1. Download `tl_localization.bat`
2. Run it and choose **[1] Install**
3. Select your game folder when the dialog opens
4. Start the game through the Astrum launcher

To revert, run `tl_localization.bat` again and choose **[2] Uninstall**.

> Close the game before installing or uninstalling.

---

## How it works

The installer downloads the latest scripts and `Game.locres` from this repository, then places the file at:

```
<GameDir>\Content\Localization\Game\ru\Game.locres
```

It also moves `pakchunk-Localization-ru.pak` and `.sig` into a timestamped backup folder so the loose file takes priority. Uninstall restores everything from that backup.

---

## Safety

- No `.exe` or `.dll` modification
- No game memory access
- No anti-cheat bypass
- No encrypted signature tampering
- Uses the Unreal Engine 5 loose files feature — the engine loads localization files from disk before pak archives, so no pak modification is needed


---

## Notes

- Some skill and item descriptions may differ from the current Astrum balance, as the translation is based on the Global/Steam build.
- If you find an incorrect description, report it in Discord: **@yashaz**
