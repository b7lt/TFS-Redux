# TFS Redux
Place prop_dynamic_overrides, edit their appearance and properties, and build cool stuff! This is an updated and improved version of KTM's TFS plugin (short for Team Fortress Sandbox).


## Features (so far):
```
- Spawn in props! Edit the prop list by editing proplist.cfg. Old plugin had hardcoded prop lists
- Move and rotate props around via the Manipulate menu!
- Edit various properties of props, such as rotation, color, collision, transparency, saturation, and size with the Edit menu!
- Delete a single prop you are looking at, or clear all of your props at once!
- Cvar that sets everyone's personal prop limit!: sm_tfs_proplimit (def. 50)
- TFS Admin Menu
- Player collision check after prop manipulation. This stops propblocking
```

## Commands and ConVars
```
- sm_tfs: Opens up the main menu
- sm_tfs_admin: Quickly brings up the Admin menu (also shown in sm_tfs if have access to this cmd)
+ sm_tfs_proplimit (def. 50): Proplimit for each user
```

## CREDITS:
- KTM: He developed the original TFS Plugin that was used for the {SuN} and {SuN} Revived servers.
- chundo: His 'Help Menu' plugin helped me learn how to use config files to create menus.
- The {SuN} Community and Staff: For being part of the best gaming community I've ever been in. ALL of you are awesome!

## To do:
```
- Add more props to proplist.cfg (event props, weapon mdls, hat mdls, etc)
- Personal player settings (manipulate beam color, POSSIBLE different entity types such as prop_physics, etc)
- Dead/Spec Player Checks
- Support for no build and build zones (prob with named trigger_multiple)
- Another config file for setting things such as sounds, manipulation beam textures, etc
- More cvars, such as one to toggle the plugin, and to toggle (no)build zones
- Custom model support (Minecraft blocks?!?!)
- More edit options? Rainbow paint?
- More advanced permission/flag handling? Instead of just one for sm_tfs and sm_tfs_admin
- About menu in sm_tfs that's toggable via cvar
- More propblock preventions
```
