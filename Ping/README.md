**Ping**

Ping is a fork of the **Spy** addon by Slipjack, renamed so that both can be
installed and run at the same time. It uses its own saved variables, frame names
and slash command (`/ping`), so it shares nothing with Spy and cannot overwrite
it. To copy existing history, enable Spy for one login and use **Ping Settings >
Data > Spy Import**. The importer merges all lists or only Kill On Sight and
never changes Spy's own saved data.

Changes from Spy include confirmed-heal healer detection, class focus, enemy
cooldown tracking, a rebuilt options panel, color themes, and nameplate/view
distance controls. Ping also has native import/export codes under **Data > Import
/ Export** for selected lists, spell rules, and appearance settings.

The **Look** category is a single scrollable page: window/theme controls first,
then row and typography controls. The **Blacked Out** theme removes nearly all
color and reduces class-bar fill while keeping combat signals legible. Theme
palettes now include semantic colors for utility icons, navigation arrows, the
enemy count, and the close button, so switching themes replaces the whole header
palette instead of leaving colors behind.

The full-artwork presets include **Obsidian Tactical**, **Arcane Glass**,
**Warcamp**, **Minimal Ink**, **Clean Glass**, **Unitframe Clean**, and
**Villain HUD**. Each adds compact history, targeting, navigation and close artwork,
its own generated material panel, semantic chrome colors, and readable class
fills. Choosing any classic color theme restores Ping's legacy artwork, so the
redesigns can be tested without committing the profile to them.

Villain HUD also uses a theme-scoped comic typography hierarchy: OFL-licensed
Bangers for its title, Expressway for readable player names, and OFL-licensed
Bebas Neue for the count and level/class data. Switching themes restores the
font selected in Ping's normal Look settings.

**Data > History** contains a per-character, newest-first encounter timeline for
sightings, hostile attacks, healer confirmations, watched cooldowns, stealth,
kills, and deaths. The newest 250 entries are retained and the text can be copied.

Healing spells can be edited under **Ping Settings > Target Picker > Healers**.
Enter one spell name, spell ID, or shift-clicked spell link per line. Spells shown
on enemy bars can be edited under **Target Picker > Cooldowns**; those entries
need a spell ID (a shift-clicked spell link includes one automatically).

---

The Ping addon scans for enemy players and announces their presence when they are detected. 

**Description**
The Ping addon scans the combat log for actions performed by enemy players and announces their presence when they are detected. By warning you about nearby enemy players you can prepare for possible PvP combat. If an enemy player is detected Ping will attempt to determine their class, race and level based on the ability that was used. It will then sound an alert and add the enemy player to the Nearby List. Ping can be configured to announce enemy player encounters and share data with other Ping users in your party, raid or guild. 

**The Ping Window**
The Ping Window will initially appear under your character's portrait, but can be moved by dragging the title bar. The title bar contains the following buttons:
- Stats: Opens the Statistics Window which shows a list of all enemies encountered
- Clear: Manually clears all enemy players that have currently been detected. 
  + Holding the Control key down while clicking this button will turn off/on Ping.
  + Holding the Shift key down while clicking this button will turn off/on all audio alerts. 
- Left/Right: Used to navigate between the Nearby, Last Hour, Ignore and Kill On Sight Lists. 
- Close: Hides the Ping window. 
  + Ping is configured by default to show itself again when the next enemy player is detected. Alternatively you can type `/ping show` to manually show the Ping window.

**The Nearby List**
As enemy players are detected they will be added to the Nearby list. Hovering over entries in the list will display a tooltip with the enemy player's details, including the last seen time and location. Right-clicking on them will displays a drop down menu which will allow you to:
  - Remove the enemy player from the Nearby List. 
  - Add/remove the enemy player to/from your Ignore or Kill On Sight List. 
  - Announce the enemy player's details to a chat channel of your choice. 
  - Set multiple Kill On Sight reasons, if the player is on your Kill On Sight list.
If the enemy player remains undetected they will be removed from the Nearby list after a configurable amount of time. The Nearby list will always sort by the time each enemy player was initially detected, with enemy players who are on the Kill On Sight list or actively performing actions being placed at the top of the list. Ping is configured by default to switch back to the Nearby List when the next enemy player is detected.

**The Last Hour List**
The Last Hour List displays enemy players that have been detected in the last hour. It will always be sorted by the time each enemy player was initially detected, with those most recently detected appearing at the top of the list.

**The Ignore List**
The Ignore List can be used for enemy players you have deemed harmless. Ping will not generate any alerts for enemy players on your Ignore list. You can use the drop down menu to add/remove enemy players to/from the Ignore list, or hold down the Control key while clicking on an entry in the list to add/remove enemy players.

**The Kill On Sight List**
The Kill On Sight list is for enemy players you especially want to know about. When enemy players on your Kill On Sight list are detected a warning will be displayed and an alarm will sound. You can use the drop down menu to add/remove enemy players to/from the Kill On Sight list, or hold down the Shift key while clicking an entry in the list to add/remove enemy players.

**The Statistics Window**
The Statistics window contains a list of all enemy encounters. By default it is sorted by the last time an enemy was detected. It can be also sorted by name, level, guild, wins and losses. The Statistics window also provides the capability to search for a specific enemy by name or guild and has filters to show enemies that are marked as Kill on Sight, with a Win/Loss or entered Reasons. 

**The Kill On Sight Button**
If enabled, this button will be located on the enemy players target frame. Clicking on this button will add/remove the enemy target to/from the Kill On Sight list. Right clicking on the button will allow you to enter Kill on Sight reasons.

***Minimap Detection***
If you can track humanoids then you will be able to detect known enemies by moving the cursor over their position on the minimap. This does not work in battlegrounds and arenas. The level and class of known enemy players will be displayed in the minimap's tooltip.

***Slash Commands***
To see a list of slash commands type: `/ping`
	`/ping` : shows the list of slash commands.
	`/ping enable` : enables and displays the Ping window.
	`/ping show` : displays the Ping window.
	`/ping reset` : resets the Ping window to the middle of the screen.
	`/ping clear` : clears the list of players that have been detected.
	`/ping config` : opens the Interface Addons window to the Ping options.
	`/ping ignore <name>` : Add/remove an enemy player to/from the Ignore List.
	`/ping stats` : opens the Statistics window. 
	
**Additional Information**
For more information see the tooltips associated with each option in the Interface Addons Ping configuration menu. 

**Comments and Suggestions**
Comments and suggestions are welcome. To report issues or ask for new features, use this site:
https://www.curseforge.com/wow/addons/ping/issues

**Localizations**
Currently enUS, deDE, koKR, ptBR, zhCN and zhTW. 
Contact me if you are able to provide translations for other languages.

**Author**
Oomkill

Ping is a fork of Spy by Slipjack, originally created by Immolation.

---------

**How can Ping help you?**

***Do NOT want to be ganked***
Ping will alert you whenever an enemy player is detected, it will be harder for them to attack you by surprise but you should quickly decide whether to fight or run.

***Want to be the one to do the ganking***
Ping will alert you whenever an enemy player is detected, however you will still need to find them to initiate combat. Range and line of sight will still be a factor depending on what class you are playing. 

***Know when your enemies are nearby***
Ping will sound an alarm when a Kill On Sight enemy player is detected. Usually you would only add an enemy player to your Kill On Sight list when you are certain they will attack you. Ping will remember who your enemies are and will alert you when they are detected.

***Know when enemy players use stealth capabilities***
Ping will warn and sound a specific alert when it detects that an enemy player is GOING into stealth. You should no longer be surprised by rogues or druids in the area but attacks from stealth could still be deadly.  

***Looking for enemy players***
Enemy players will automatically be added to the Nearby list whenever they attempt any combat action. You can use the Ping to locate them as you move around a zone and they come within range.

***Getting help when you encounter enemy players***
Ping can be used to announce encounters to your party, raid and guild. Other Ping users in your party, raid or guild who are also in the same zone will have your encounters added to their Nearby lists. This is a great way for a guild to track down their enemies.

***Get revenge on an enemy player's guild***
Ping is also capable of displaying a warning when a player in the same guild as someone on your Kill On Sight list is detected. This option can be enabled or disabled via the Interface Addons window.

***Knowing how many times you've won or lost against an enemy player***
Ping will record when you get a killing blow against an enemy player. Likewise, it will also record when an enemy player gets a killing blow against you. These statistics can be seen in the tooltip that appears when you hover over the enemy player's entry in the lists and is shown in the statistics window.

**Common Questions**

***Why doesn't Ping work while I am in combat?***
The game has restrictions on what addons can do during combat. Clicking on enemy players in the lists will not work during combat. Ping also does not display newly detected players while you are in combat. However, Ping will still give visual and audio alerts both in and out of combat.

***Why does Ping show only a maximum of fifteen enemy players?***
While the fifteen enemy player limit at any one time could easily be changed, I believe that displaying any more than fifteen will make it more difficult to use the information Ping reports. Long lists of enemy players will either take up too much real-estate on screen, or require the introduction of list paging which would make the addon more cumbersome. The limit may be an issue for some users, but it is alleviated by the fact that the most active enemy players or those on your Kill On Sight list will always appear at the top of the list.

***I was just attacked by an enemy player from stealth. Why didn't Ping warn me?***
If an enemy player doesn't perform any actions recorded in your combat log then Ping will not know they are there. In this case, the enemy player may have gone into stealth far enough away from you that it isn't reported in your combat log or the enemy player could have already been in stealth before you arrived in the area. Regardless if you got a warning or not, enemies with Stealth capabilities will always have the first strike advantage.  

***Why can't I target an enemy player Ping has just reported?***
The most likely explanation for this - if you are not in combat - is that while they are near, they are not within targeting range. 

***Why doesn't Ping work in sanctuaries?***
Ping doesn't work in sanctuary locations such as Dalaran or Shattrath City because PvP combat is disabled for all players. 

***How can I turn off Ping temporarily?***
This can be done by holding the Control key while clicking the Clear button in the title bar. You may want to do this when there are a lot of enemy players around and you don't want the continuous alerts.

***I don't want a warning to be displayed or any alerts to sound. How can I turn them off?***
This can be done by holding the Shift key while clicking the Clear button in the title bar. You may want to do this when there are a lot of enemy players around and you don't want to hear the audio alerts.

***How do I retain my KoS list and win/loss records beyond 90 days***
The data management options were designed to reduce the overall size of the database and will purge players based on the time settings. If you check the options:
 - Purge Kill on Sight players based on undetected time
     and
 - Purge win/loss data based on undetected time
then enemy players will be removed based on the number of days selected (i.e., 90 days). If all you want to retain is the win/loss data beyond 90 days - you just need to ensure that option remains unchecked. If you also want to retain players on your Kill on Sight list where a Killing Blow was not recorded - you will also need that option unchecked.
