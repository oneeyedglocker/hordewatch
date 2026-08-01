PingData = Ping:NewModule("PingData")
local L = LibStub("AceLocale-3.0"):GetLocale("Ping", true)

local Ping = Ping

local bor = bit.bor
local band = bit.band
local time = time

local Ping_db = {
    session = {
        players = {},
    },
    pvp = {
        incoming = {},
        outgoing = {},
    },
    ignored = {},
    tooltips = {
        pets = {},
    },
}

-- session pointers to units
setmetatable(Ping_db.session.players, {
    __mode = "k",
    __index = function(t, k)
        rawset(t, k, {})
        return t[k]
    end,
})

-- pvp timer pointers to units
setmetatable(Ping_db.pvp.incoming, {__mode = "k"})
setmetatable(Ping_db.pvp.outgoing, {__mode = "k"})

local cache = {
    players = {
        name = {data = {}},
        level = {data = {}},
        class = {data = {}},
        guild = {data = {}},
        wins = {data = {}},
        loses = {data = {}},
		time = {data = {}},
    },
r}

-- cache pointers to units
setmetatable(cache.players.time.data, {__mode = "v"})

-- temporary table pool
local tp = {}
setmetatable(tp, {__mode = "k"})

local function getTable()
    local t = next(tp) or {}
    tp[t] = nil
    return t
end

local function releaseTable(t)
    if type(t) ~= "table" then
		return
	end
    for k in pairs(t) do t[k] = nil end
    t[1] = true; t[1] = nil
    tp[t] = true
    return nil
end

local emptyTable = {}

function PingData:OnInitialize()
    Ping:SetDataDb(Ping_db)  --> Ping.lua
end

function PingData:OnEnable()
    -- unit testing
    if PingUnitTest then
		PingUnitTest:LoadData(Ping_db, cache)
	end
end

function PingData:SetSavedVariablesDb(val)
	Ping_db.units = PingDB.kosData[Ping.RealmName][Ping.FactionName][Ping.CharacterName].unit	
end

function PingData:GetUnitSession(unit) --++
--    if unit.isEnemy then	
        return Ping_db.session.players[unit]
 --   end
end

function PingData:SetUnitReason(unit, reason)  --??
    if unit.isEnemy then
		unit.reason = reason
	end	
end

function PingData:AddPlayer(unit)  -- Delete
    if unit.isEnemy then	
		PingPerCharDB.PlayerData[unit.name] = unit
		PingDB.kosData[Ping.RealmName][Ping.FactionName][Ping.CharacterName][unit.name] = unit	
	end
end

function PingData:IsPlayer(name)  --??
    return (PingPerCharDB.PlayerData[name] and true or false)
end

function PingData:GetPlayer(name) --++
    return PingPerCharDB.PlayerData[name]
end

function PingData:SetPlayerKos(unit, value) --??
    assert(unit, "Invalid unit (" .. tostring(unit) .. ")")
    if unit.isEnemy then
		unit.kos = (value and 1 or nil)
	end	
end

-- set unit pvp flag to current time. 
function PingData:LogPvp(unit)
    assert(unit, "Invalid unit (" .. tostring(unit) .. ")")
    assert(unit.type, "Invalid unit type (" .. tostring(unit.type) .. ")")
    Ping_db.session.players[unit].pvp = time()
end

-- set attack time - kills within 60 seconds are credited as a win
function PingData:LogOutgoingPvp(unit)  --??
    assert(unit, "Invalid unit (" .. tostring(unit) .. ")")
    assert(unit.type, "Invalid unit type (" .. tostring(unit.type) .. ")")
    Ping_db.pvp.outgoing[unit] = time()
end

-- set hostile attack time - death within 60 seconds are credited as a win
function PingData:LogIncomingPvp(unit)  --??
    assert(unit, "Invalid unit (" .. tostring(unit) .. ")")
    assert(unit.type, "Invalid unit type (" .. tostring(unit.type) .. ")")
    Ping_db.pvp.incoming[unit] = time()
end

-- add win to hostile win counter
function PingData:LogHostilePvpDeath(unit, session) --??
    assert(unit, "Invalid unit (" .. tostring(unit) .. ")")
    assert(unit.type, "Invalid unit type (" .. tostring(unit.type) .. ")")

    local now = time()

    -- save time of death to ignore dots events that may occur after death
    session.dead = now

    -- add to win count if final attack was within 60 seconds
    if Ping_db.pvp.outgoing[unit] and (Ping_db.pvp.outgoing[unit] > (now - 60)) then
        unit.wins = (unit.wins and (unit.wins + 1) or 1)
        Ping_db.pvp.outgoing[unit] = nil
        Ping_db.pvp.incoming[unit] = nil
    end
end

-- add loss to hostile death counters
function PingData:LogMyPvpDeath()
    local now = time()

    -- all hostiles that attacked within 60 seconds are credited with a win
    for unit, time in pairs(Ping_db.pvp.incoming) do
        if time > (now - 60) then
            unit.loses = (unit.loses and (unit.loses + 1) or 1)
            Ping_db.pvp.outgoing[unit] = nil
            Ping_db.pvp.incoming[unit] = nil
        end
    end
end

-- removes entries from the incoming and outgoing pvp lists if older than 60 seconds
function PingData:PurgePvpTimers()
    local now = time()

    -- clean up other expired timers
    for unit, time in pairs(Ping_db.pvp.incoming) do
        if time < (now - 60) then
            Ping_db.pvp.incoming[unit] = nil
        end
    end

    for unit, time in pairs(Ping_db.pvp.outgoing) do
        if time < (now - 60) then
            Ping_db.pvp.outgoing[unit] = nil
        end
    end
end

do -- PingData:SortPlayersByTime()
    local function sorter(a, b)
        return a.time > b.time
    end

    function PingData:SortPlayersByTime()
        local cache = cache.players.time.data
        local i = 1

        for _, unit in pairs(PingPerCharDB.PlayerData) do
            cache[i] = unit
            i = i + 1
        end

        for j = i, #cache do cache[j] = nil end
        table.sort(cache, sorter)
    end
end

do -- PingData:GetPlayers() - Iterators
    local sorters = {
        ["name"] = function (a, b) return (a.name and a.name or "") < (b.name and b.name or "") end,
        ["level"] = function (a, b) return (a.level and (a.level > 0 and a.level or 255) or 0) > (b.level and (b.level > 0 and b.level or 255) or 0) end,
        ["class"] = function (a, b) return (a.class and a.class or "zzzzzz") < (b.class and b.class or "zzzzzz") end,
        ["guild"] = function (a, b) return (a.guild and a.guild or "zzzzzz") < (b.guild and b.guild or "zzzzzz") end,
        ["wins"] = function (a, b) return (a.wins and a.wins or 0) > (b.wins and b.wins or 0) end,
        ["loses"] = function (a, b) return (a.loses and a.loses or 0) > (b.loses and b.loses or 0) end,
        ["time"] = function (a, b) return (a.time and a.time or 0) > (b.time and b.time or 0) end,
    }

    local function sort(sortBy)
        local cache = cache.players[sortBy].data
        local i = 1
        for _, unit in pairs(PingPerCharDB.PlayerData) do
            cache[i] = unit
            i = i + 1
        end

        for j = i, #cache do cache[j] = nil end
        table.sort(cache, sorters[sortBy])
    end

    local function iterator(data, index)
        index = index + 1
        if data[index] then
            return index, data[index], Ping_db.session.players[data[index]]
        else
            return
        end
    end

    function PingData:GetPlayers(sortBy)
        if not sortBy then sortBy = "time" end
        sort(sortBy)
        return iterator, cache.players[sortBy].data, 0
    end
end