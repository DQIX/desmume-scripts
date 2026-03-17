## [DQ9] Item Respawn Display (USA)
- Displays fountain group in the top left corner
- Displays respawn timers and capacity indicators for all 89 sparkly spot nodes in the game
### How to Use
- Press Start to toggle visibility on/off
- Timers in cyan are influenced by fountain group
- Capacity indicators change from grey (0) to white (partially filled) to green (full)
### Sparkly Spot Memory Map (USA)
https://docs.google.com/spreadsheets/d/10mJKk1UM4PxSw5kyCHiDB-KaqtN5uXtvx_wuMpuWnFU/edit?usp=sharing
### Addresses (USA)
- `0x020F90B2` = fountain group
- `0x020F90B8` = first node in the node array
- `0x020FD764` = number of guests tagged
### About Nodes
One node in the array is a 32bit packed bitfield:
- Bits 0-8: active timer in raw minutes
- Bits 9-12: maximum capacity (not used for the fountain)
- Bits 17-24: current capacity
- Bits 25–28: duration step count

`FUN_0208EC78` (USA) handles all of the above and `FUN_0208F048` (USA) handles the fountain's maximum capacity. Duration step count is multiplied by 30 (minutes) to get the total respawn time.
### About Respawns
The number of items that can respawn after each completion of the timer is based on the A-Table for normal sparkly spots. It can be a number from 0 to the number of empty slots. This can be manipulated with map methods:
- Freeze AT
- Set your AT position 1 seed before the desired output
- The next seed's output will be used in the following calculations once the timer ends:
```lua
local function rand_range(maximum)
    if maximum == 0 then
        return 0
    end
    local rand = AT_rand()
    return math.floor((rand * maximum) / 32768)
end

local function spawn_count(maximum, current)
    local spawn
    if current == 0 then
        spawn = rand_range(maximum + 1)
    elseif current >= maximum then
        spawn = 0
    else
        spawn = rand_range(maximum - current + 1)
    end
    return spawn
end
```
### About the Fountain (Stornway Inn Basement)
The fountain gets completely topped up an hour after the last item was picked up. The fountain is actually 2 nodes with 7 items each, instead of 1 node with 14 items (for a maxed out inn). The game starts with 4 items in the first node and adds 1 item every 100 tags. Once you have 7 items, the 8th to 14th items will then be unlocked in the second node. For that reason, there are actually 2 timers for the fountain, although they're basically treated like one.
### About Fountain Groups
A save file's fountain group is determined after the MC is created, shortly after the screen turns black. It's based on the A-Table as well. It seems to consistently use the 9th position of an initial seed with the buffer technique. The fountain group ID (0-7) is simply produced from:
```
(15bit AT output) % 8
```
The function responsible is `FUN_0208EA10` (USA).
### Special Thanks
- Gradis for providing the sprite of Stornway's inn sign
- Adenine's save editor for item sprites
  - https://github.com/DQIX/editor/blob/main/src/assets/itemIcons.png
- Yacker's version of DeSmuME with breakpoints
  - https://github.com/Yackerw/desmume/releases/tag/DebugRelease_0_1
- The Quester's Rest Discord server
  - https://discord.com/invite/B3rjhdfG5m
