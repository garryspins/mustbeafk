/*
    MustBeAFK
    A T6 Zombies AFK System by MustBeLeaving
    You can find this script at https://github.com/garryspins/mustbeafk

    Requires:
        t6-gsc-utils (https://github.com/fedddddd/t6-gsc-utils)

    DVars:
        mafk_name       [str = "[^6MAfk^7]"]- What text should be shown before chat messages?
        mafk_prefix     [str   = ".afk"]    - What should the prefix be for the chat commands?

        mafk_burps      [bool  = 1]         - Should the player burp when the afk timer is up?
        mafk_hud        [bool  = 1]         - Should the message saying youre afk be shown on screen?

        mafk_user_times [bool  = 0]         - Should the user be able to specify a time to go afk for?
        mafk_max_time   [float = 15]        - If user_times, what should the max time allowed be in minutes?
        mafk_def_time   [float = 15]        - If user_times, what should the default time be if none is specified?
    
        mafk_time       [float = 15]        - If not user_times, what should the afk time be? if 0 then time is infinite.

        mafk_max_end    [bool  = 0]         - End the game if everyone is either down or afk?

        mafk_cooldown   [float = 15]        - How many minutes should you have to wait before using afk again.
*/

#include maps\mp\_utility;
#include maps\mp\gametypes_zm\_hud_util;

// you know
init() {
    level.mafk_name         = getDvarStringDefault("mafk_name",   "[^6MAfk^7]");
    level.mafk_prefix       = getDvarStringDefault("mafk_prefix", ".afk"  );

    level.mafk_burps        = getDvarIntDefault("mafk_burps",      1) == 1;
    level.mafk_hud          = getDvarIntDefault("mafk_hud",        1) == 1;

    level.mafk_user_times   = getDvarIntDefault("mafk_user_times", 0) == 1;
    level.mafk_max_time     = getDvarFloatDefault("mafk_max_time", 15);
    level.mafk_def_time     = getDvarFloatDefault("mafk_def_time", 15);

    level.mafk_time         = getDvarFloatDefault("mafk_time",     15);
    level.mafk_infinite     = level.mafk_time == 0;

    level.mafk_max_end      = getDVarIntDefault("mafk_max_end",     0) == 1;

    level.mafk_cooldown     = (getDvarFloatDefault("mafk_cooldown", 15) * 60) * 1000;

    onPlayerSay(::hook_chat);
    
    if (level.mafk_max_end) {
        level thread watchAllDownOrAFK();
    }

    if (level.mafk_cooldown != 0) {
        level thread watchCooldown();
    }
}

// a default string dvar getter
// since this doesnt exist anywhere in the std 
getDvarStringDefault(dvar, def) {
    value = GetDVar(dvar);

    if (value != "") {
        return value;
    }

    return def;
}

// trims the whitespace around a string
// only really used once but still
strtrim(str) {
    padl = 0;
    padr = 0;
    for (i = 0; i < str.size; i++) {
        if (str[i] == " ") {
            padl = i;
        } else {
            break;
        }
    }

    for (i = 0; i < str.size; i++) {
        if (str[str.size - i] == " ") {
            padr = i;
        } else {
            break;
        }
    }

    return getSubStr(str, padl, str.size - padr);
}

// this is manual modulo
// you dont have to tell me how stupid this is, i know!
// modulo is just refusing to work properly in some places 
// and i have absolutely no idea why
// so have fun with this!
mod(num, modby) {
    while (num >= modby) {
        num = num - modby;
    }

    return num;
}

// floor function since it doesnt exist for some reason!
// modulo works here?
floor(num) {
    return num - (num % 1); 
}

// formats a time from ms into a pretty string
// this can be improved obviously
fmttime(ms) {
    ms = floor(ms);
    seconds = mod(floor(ms / 1000), 60);
    minutes = mod(floor((ms / 1000) / 60), 60);
    hours = floor(floor((ms / 1000) / 60) / 60);

    if (hours) {
        text = hours + " hour";

        if (hours > 1) {
            text = text + "s";
        }

        if (minutes) {
            text = text + " and " + minutes + " minute";

            if (minutes > 1) {
                text = text + "s";
            }
        }

        return text;
    }

    if (minutes > 0) {
        text = minutes + " minute";

        if (minutes > 1) {
            text = text + "s";
        }

        if (seconds) {
            text = text + " and " + seconds + " second";

            if (seconds > 1) {
                text = text + "s";
            }
        }

        return text;
    }

    if (seconds > 1) {
        return seconds + " seconds";
    }
    
    if (seconds == 1) {
        return seconds + " second";
    }

    return "no time";
}

// watch for if every player is either down or afk
// if they are then end the game
watchAllDownOrAFK() {
    for(;;) {
        players = getplayers();
        count = 0;
        afk = 0;

        foreach(ply in players) {
            if (!isAlive(ply)) {
                count++;
            } else if (ply.afk) {
                count++;
                afk++;
            }
        }

        if ((count == players.size) && (afk != 0)) {
            level notify("end_game");
        }

        wait 5;
    }
}

// set the players cooldown
// this is separate from set_afk because
// we like to be a little efficient around these parts
watchCooldown() {
    for (;;) {
        self waittill("mafk_set", ply, val);

        if (val == false) {
            ply.mafk_cooldown = getTime() + self.mafk_cooldown;
        }
    }
}

// burps! but only if we want burps
burp() {
    if (level.mafk_burps) {
        self maps\mp\zombies\_zm_audio::playerexert("burp");
    }
}

// sets the player to be afk or not, accepts a boolean
// this doesnt do anything except set some values on the player
// if you wish to extend anything use the notification
set_afk(value) {
    self.afk = value;
    self.afk_notify_half = false;

    self freezeControls(value);
    self.ignoreme = value;
    
    if (value) {
        self enableInvulnerability();
    } else {
        self disableInvulnerability();
    }

    level notify("mafk_set", self, value);
}

// this is the actual logic behind the chat command
// just a series of checks
quick_afk_on(time) {
    // is the player down
    if (self.sessionstate == "spectator" || !isAlive(self)) {
        self tell(level.mafk_name + " You must be alive to go AFK.");
        return false;
    }

    if (isDefined(self.mafk_cooldown)) {
        if (self.mafk_cooldown >= getTime()) {
            self tell(level.mafk_name + " You must wait ^4" + fmttime(self.mafk_cooldown - getTime()) + "^7 before going afk again.");
            return false;
        }

        self.mafk_cooldown = undefined;
    }
    
    if (self.afk) {
        if (isDefined(self.mafk_endtime)) {
            self tell(level.mafk_name + " You are already AFK, if you would like to go un-afk type ^2.afk off");
            self tell(level.mafk_name + " You have ^4" + fmttime(self.mafk_endtime - getTime()) + "^7 left");
        } else {
            self tell(level.mafk_name + " You have as long as you want to be afk.");
        }
        return false;
    }

    if (level.mafk_infinite && !level.mafk_user_times) {
        say(level.mafk_name + " " + self.name + " has gone AFK.");
        self set_afk(true);
        
        return false;
    }

    say(level.mafk_name + " " + self.name + " has gone AFK for ^4" + fmttime((time * 60) * 1000));
    self tell(level.mafk_name + " You have gone AFK, if you would like to go un-afk type ^2.afk off");
    endtime = getTime() + ((time * 60) * 1000);
    
    self set_afk(true);

    self.mafk_endtime = endtime;
    self thread check_afk_player(endtime);

    if (level.mafk_hud) {
        self thread afk_player_hud(endtime, (time * 60) * 1000);
    }

    self burp();

    return false;
}

// what actually hooks onto chat
hook_chat(text, mode) {
    text = strtrim(toLower(text));

    split = strTok(text, " ");

    if (split[0] != level.mafk_prefix) {
        return true;
    }

    if ((split[1] == undefined) || (split[1] == "on")) {
        if (level.mafk_user_times) {
            return self quick_afk_on(level.mafk_def_time);
        } else {
            return self quick_afk_on(level.mafk_time);
        }
        return false;
    }

    if (level.mafk_user_times) {
        switch (split[1]) {
        case "off":
            self tell(level.mafk_name + " You're back!");
            self set_afk(false);
            self notify("afkcancel");
            break;
        case "time":
        case "left":
            if (self.afk) {
                self tell(level.mafk_name + " You have ^4" + fmttime(self.mafk_endtime - getTime()) + "^7 left");
            } else {
                self tell(level.mafk_name + " You are not afk.");
            }

            break;
        case "help":
            self tell(level.mafk_name + " ^2" + level.mafk_prefix + " [number]^7 - Turns on afk for the given amount of time (^2" + mintime + "^7 to ^2" + level.mafk_max_time + "^7 minutes)");
            self tell(level.mafk_name + " ^2" + level.mafk_prefix + " off^7   - Turns off afk");
            self tell(level.mafk_name + " ^2" + level.mafk_prefix + " help^7  - Shows this message");
            self tell(level.mafk_name + " ^2" + level.mafk_prefix + " time^7  - Shows how long youre allowed to be afk");
      
            break;
        default:
            mintime = 1;
            time = int(split[1]);

            if ((time < mintime) || (time > level.mafk_max_time)) {
                self tell(level.mafk_name + " Please give a valid time from ^2" + mintime + "^7 to ^2" + level.mafk_max_time + "^7 minutes");
                return false;
            }

            return self quick_afk_on(time);
        }

        return false;
    }

    switch (split[1]) {
    case "off":
        self tell(level.mafk_name + " You're back!");
        self set_afk(false);
        self notify("afkcancel");
        break;
    case "time":
    case "left":
        if (self.afk) {
            self tell(level.mafk_name + " You have ^4" + fmttime(self.mafk_endtime - getTime()) + "^7 left");
        } else {
            self tell(level.mafk_name + " You are not afk.");
        }

        break;
    case "help":
    default:
        self tell(level.mafk_name + " ^2" + level.mafk_prefix + " on^7 - Turns on afk");
        self tell(level.mafk_name + " ^2" + level.mafk_prefix + " off^7 - Turns off afk");
        self tell(level.mafk_name + " ^2" + level.mafk_prefix + " help^7 - Shows this message");
        self tell(level.mafk_name + " ^2" + level.mafk_prefix + " time^7 - Shows how much longer you can be afk");
    }

    return false;
}

// runs on the player to check if he should still be afk or not
check_afk_player(endtime) {
    for (;;) {
        self endon("disconnect");
        self endon("afkcancel");
        level endon("game_ended");

        time = getTime();
    
        if (time >= endtime) {
            self set_afk(false);
            self tell(level.mafk_name + " Your AFK time has expired!");
            self burp();
            self.mafk_endtime = undefined;
            break;
        }

        wait 0.25;
    }
}

// only runs if mafk_hud is 1
// draws the hud!
afk_player_hud(endtime, time) {
    if (isDefined(self.mafk_hud)) {
        return;
    }

    level endon("game_ended");
    self endon("disconnect");

    self.mafk_hud = createServerFontString("objective", 2);
    self.mafk_hud setPoint("CENTER", "TOP", 0, 0);
    self.mafk_hud setText("You are currently afk");
    
    self.mafk_hud.hideWhenInMenu = 1;

    for(;;) {
        if ((getTime() >= endtime) || !self.afk) {
            self.mafk_hud destroy();
            break;
        }

        // logic to make it slowly fade
        self.mafk_hud.alpha = ((endtime - getTime()) / time) + 0.75;

        wait 0.50;
    }
}