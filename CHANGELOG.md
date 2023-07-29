# Changelog

## [1.0.1] - 2023-07-29

### Fixed

- Properly call activity registration by event system.
  Fixes a LUA error when entering a dungeon or starting a mythic keystone.

## [1.0.0] - 2023-07-27

### Added

- Record player activity when engaging a boss.
- Look up player activity list when joining a group or another player joins your group.
- Print a notification message in the player's chat frame informing about any known characters.
- Extend unit tooltips with activity history (max. 5 entries)
- Hold Shift to show timestamps in unit tooltips.
- Add tooltips for LFG application list for any applicant, even when you are not the current group leader.
- Add tooltips for LFG group browser (shows information about leader only).
- Activate LFG application list interactions when not the current group leader.
