# MustBeAfk
I was having trouble finding a good AFK system so I decided to make one was nice.

![When AFK](https://i.imgur.com/qYqfVzG.jpeg)

## Features
- Very customizable
- Users are able to specify a time to go AFK for
- HUD element that appears when AFK
- Commented Code
- Chat-Based
- Burp to indicate that you aren't afk anymore (for tabbed out players)
- Infinite AFK time

## Downloads
Note that this requires [T6 GSC Utils](https://github.com/fedddddd/t6-gsc-utils).

[Source code](https://github.com/garryspins/mustbeafk)
[Compiled](https://github.com/garryspins/mustbeafk)

## Configuration DVars
- `mafk_name [str = "[^6MAfk^7]"]` - Tag before messages from the system
- `mafk_prefix [str = ".afk"]` - The command the system will use

- `mafk_burps [bool = 1]` - Should the player burp when going afk and un-afk
- `mafk_hud [bool = 1]` - Should the HUD be shown for afk players

- `mafk_user_times [bool  = 0]` - Should the user be able to specify a time to go afk for?
- `mafk_max_time [float = 15]` - If user_times, what should the max time allowed be in minutes?
- `mafk_def_time [float = 15]` - If user_times, what should the default time be if none is specified?
- `mafk_time [float = 15]` - If not user_times, what should the afk time be? if 0 then time is infinite.
- `mafk_max_end [bool  = 0]` - End the game if everyone is either down or afk?

- `mafk_cooldown [float = 15]` - How many minutes should you have to wait before using afk again.

## Images
![When Already AFK and trying to be AFK again](https://i.imgur.com/JircCiK.png)
