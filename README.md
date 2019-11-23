![Supreme Risk Banner](promo/signature3.jpg)

# Supreme Risk

Supreme Risk is a Map for Supreme Commander and Supreme Commander Forged Alliance Forever, enabling rules from the board game "RISK"

![Supreme Risk Screenshot](promo/Risk%20Screenshots/Board3.png)
![Supreme Risk Screenshot](promo/Risk%20Screenshots/board5.png)

## History

I first wrote this Map back in 2007, and recently picked it up again to make it compatible with modern FA.

## How to Play
### Getting Started 

* Install the Forged Alliance Forever Multiplayer client http://faforever.com/ 
* You need a valid license of "Supreme Commander: Forged Alliance" (from steam or other sources)
* Once in the client, go to "Vault" and search for "Supreme Risk". 
* Click "Install" then "Create Game"

### Manual Installation

this should not be needed for players, I update the version in the vault regularly
If you make changes to the map, however: 

* Install FA (see above)
* Copy the folder Supreme_Risk.v0012 to %USERPROFILE%\Documents\My Games\Gas Powered Games\Supreme Commander Forged Alliance\maps\

### Gameplay

* Gameplay is split into rounds (10 to 60 seconds depending on game settings) 
* Players can reinforce territories, defend and liberate neighbouring countries
* Standard Risk rules apply when determining victories, and new units to be placed

* Options available in the game settings
  * Choose tier of units to use (T1, T2, T3)
  * Lose or retain reinforcements
  * unit movement settings
  
### Gameplay FAQ
* How do I build units?
   * Each Factory has up to 3 different units on display, which will build 1, 5, or 10 units at once respectively. You can only build units up to the reinforcements per round limit. 
* How do I know how many units I can place?
   The game will tell you in many ways:
   * The mass income (+3) on the top-left of the screen is the number of units you can place right now. Build them in the factories. 
   * Every time you liberate a territory, or reclaim for extra units, the units you'll receive next round will be displayed in the center of the screen
* Why are my units stuck?
   * If your units appear stuck (don't move), and hovering over them says "resting", they are paused as per RISK game rules where you can only move units from one of your owned territories to another owned territoriy once per round. This can be changed in the game options to "free" for free movement, or "restricted" to have this restriction also for liberating (for even slower games)
* I don't like the missions, can I set up the game to allow conquering the whole world?
   * In the Game Lobby, set the "Victory Condition" to "Annihilation" ("Assassination" is the default and will generate the usual missions)
* How does the bonus units wreckage work?
   * At the bottom of the map, you have an "Engineering Station" building, which can reclaim the wreckage there. You need 3 wreckages of the same type, or three different types. Select the station and then right click on a wreck to receive the bonus units.
* Does the faction (uef, cybran, ...) have any effect on the game?
   * No, all players get the same units as per the "Unit Tiers" selection in the options
   
   
## Replays
37 Minutes, T3 Units, pretty much shows all the features of the game
https://content.faforever.com/faf/vault/replay_vault/replay.php?id=10531732

30 Minutes, Linus Tech Tips plays
https://content.faforever.com/faf/vault/replay_vault/replay.php?id=10558708

## Files

- Supreme_Risk.v0012 The latest version compatible with FAF
- Supreme_Risk	The version compatible with Original SupCom from 2007 (no longer maintained)


## Known Issues/Bugs

- Please report bugs here on github or in the faf community forum https://forums.faforever.com/viewtopic.php?f=41&t=18368

## ideas
- Add an "airlift" unit (econoob)
- Add more unit tiers simultaneously (todo: balancing)

## Links

- map editor logs: %APPDATA%\LocalLow\ozonexo3\FAF Map Editor
- map editor wiki: https://wiki.faforever.com/index.php?title=FA_Forever_Map_Editor#Custom_resources

- location of the map %USERPROFILE%\Documents\My Games\Gas Powered Games\Supreme Commander Forged Alliance\maps\supreme_risk.v0012

- cp -R "$USERPROFILE\Documents\My Games\Gas Powered Games\Supreme Commander Forged Alliance\maps\supreme_risk.v0012" .

- Start for testing C:\ProgramData\FAForever\bin\ForgedAlliance.exe /init init_faf.lua /nobugreport /log "C:\ProgramData\FAForever\logs\game1.log" /EnableDiskWatch
