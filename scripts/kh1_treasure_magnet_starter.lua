-- Treasure Magnet Starter v1.0.0
-- Steam Global 1.0.0.2 / LuaBackend. Standalone; no shared packages required.
-- Grants one unequipped Treasure Magnet if missing; sets its AP cost to zero.
-- Saving persists the grant. Removing this script restores AP cost on restart.
-- Address references: gaithern/KH1-LUA-LIBRARY and
-- HydroSulphide/KH1FM-Memory-Map (AbilityID.json and wiki/Ability-Data).

LUAGUI_NAME = "Treasure Magnet Starter"
LUAGUI_AUTH = "ROXASBrandon"
LUAGUI_DESC = "Unlock Treasure Magnet early and equip it for 0 AP."

local A = {
    fingerprint = 0x4698D2,
    debugString = 0x3EA388,
    beep = 0x26E20C,
    abilities = 0x2DE93A4,
    magnetCost = 0x2D26148,
    hud = 0x281249C,
    hp = 0x2D5CC4C,
    maxHP = 0x2DE9366,
    soraPointer = 0x2537E48,
    warp = 0x22EC0AC,
    cutscene = 0x23AB2D0,
    gummi = 0x5075A8,
}

local enabled = false
local stableFrames = 0
local reportedFull = false
local reportedOwned = false
local reportedFree = false
local reportedCostConflict = false

function _OnInit()
    enabled = false
    stableFrames = 0
    reportedOwned = false
    reportedFree = false
    reportedCostConflict = false
    if GAME_ID ~= 0xAF71841E or ENGINE_TYPE ~= "BACKEND" then
        ConsolePrint("Treasure Magnet Starter: KH1 LuaBackend required; disabled.")
        return
    end
    -- Refuse other releases rather than guessing at save-memory addresses.
    if ReadByte(A.fingerprint) ~= 106
        or ReadInt(A.debugString) ~= 540680280
        or ReadByte(A.beep) ~= 9 then
        ConsolePrint("Treasure Magnet Starter: unsupported executable; disabled. Requires Steam Global 1.0.0.2.")
        return
    end
    enabled = true
    ConsolePrint("Treasure Magnet Starter: Steam Global 1.0.0.2 detected. Waiting for gameplay.")
end

local function makeMagnetFree()
    -- This table is shared by all characters and all Treasure Magnet copies.
    -- Cost is the first byte, not the complete 32-bit record header: bytes
    -- +2/+3 contain other metadata and MUST be preserved (live verification).
    -- Check neighboring cost bytes before touching the one cost byte.
    -- They can be uninitialized while battle data is loading.
    if ReadByte(A.magnetCost - 12) ~= 0
        or ReadByte(A.magnetCost + 12) ~= 1
        or ReadByte(A.magnetCost + 24) ~= 1
        or ReadByte(A.magnetCost + 60) ~= 1 then
        return false
    end
    local cost = ReadByte(A.magnetCost)
    if cost ~= 0 and cost ~= 2 then
        if not reportedCostConflict then
            ConsolePrint("Treasure Magnet Starter: unexpected AP cost; cost patch skipped.")
            reportedCostConflict = true
        end
        return false
    end
    if cost == 2 then WriteByte(A.magnetCost, 0) end
    if ReadByte(A.magnetCost) ~= 0 then return false end
    if not reportedFree then
        ConsolePrint("Treasure Magnet Starter: AP cost set to 0. Equip normally in Abilities.")
        reportedFree = true
    end
    return true
end

local function inGameplay()
    -- The community's "title" address can remain 1 during normal gameplay.
    -- Menu state is not an unlock requirement either; AP is checked by the game
    -- when equipping, not when acquiring an ability.
    return ReadFloat(A.hud) == 1
        and ReadLong(A.soraPointer) ~= 0
        and ReadByte(A.hp) > 0
        and ReadByte(A.maxHP) > 0
        and ReadByte(A.warp) == 0
        and ReadByte(A.cutscene) == 0
        and ReadInt(A.gummi) == 0
end

function _OnFrame()
    if not enabled then return end
    -- Reapply if the game reloads the battle table. Do this in menus as well,
    -- so both the displayed cost and the normal equip check use zero.
    local free = makeMagnetFree()
    if not inGameplay() then
        stableFrames = 0
        return
    end
    stableFrames = math.min(stableFrames + 1, 60)
    if stableFrames < 60 then return end

    local firstEmpty = nil
    local hasMagnet = false
    -- Read the entire bounded list before writing; never overwrite an ability.
    for i = 0, 47 do
        local value = ReadByte(A.abilities + i)
        local id = value % 128
        if value == 0 then
            if firstEmpty == nil then firstEmpty = i end
        elseif id < 1 or id > 65 or firstEmpty ~= nil then
            -- Unexpected/non-contiguous data: wait without modifying it.
            return
        elseif id == 5 then
            hasMagnet = true
        end
    end
    if hasMagnet then
        if not reportedOwned then
            ConsolePrint(free
                and "Treasure Magnet Starter: already unlocked. Equip in Abilities > Sora for 0 AP."
                or "Treasure Magnet Starter: already unlocked; AP cost patch pending.")
            reportedOwned = true
        end
        return
    end
    if firstEmpty == nil then
        if not reportedFull then
            ConsolePrint("Treasure Magnet Starter: ability list full; no changes made.")
            reportedFull = true
        end
        return
    end
    WriteByte(A.abilities + firstEmpty, 0x85)
    reportedOwned = true
    ConsolePrint(free
        and "Treasure Magnet Starter: unlocked! Equip in Abilities > Sora for 0 AP, then save."
        or "Treasure Magnet Starter: unlocked! AP cost patch pending; save to retain the ability.")
end
