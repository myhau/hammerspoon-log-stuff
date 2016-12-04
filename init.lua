-- UTIL


function tableKeys(tab)
    local outKeys = {}
    for k, v in pairs(tab) do
        table.insert(outKeys, k)
    end
    return outKeys
end


-- CODE

local PERIODICAL_STUFF_INTERVAL_SECONDS = 10

local BASE_HISTORY_DIR = "/Users/mihau/.hammerspoon-history/"

function openHistory(name)
    local fPath = BASE_HISTORY_DIR .. "." .. name .. "history"
    local descriptor = io.open(fPath, "a")
    return descriptor
end

function writeHistory(file, data)
    local time = os.time()
    file:write(time .. " " .. data .. "\n")
end

local keyFile = openHistory("key")
--local locationFile = openHistory("location")
local wifiFile = openHistory("wifi")
local itunesHistory = openHistory("itunes")
local spotifyHistory = openHistory("spotify")
local appEventsHistory = openHistory("application")

local keyEvents = hs.eventtap.new({ hs.eventtap.event.types.keyDown },
    function(event)
        hs.timer.doAfter(1, function()
            local modifiers = tableKeys(event:getFlags())
            local key = hs.keycodes.map[event:getKeyCode()]
            local strKey = key
            if (#modifiers > 0) then strKey = "+" .. strKey end
            local keyAndModifiersString = table.concat(modifiers, "+") .. strKey
            writeHistory(keyFile, keyAndModifiersString)
        end)
        return false
    end)
keyEvents:start()

applcationEventMap = {
    [hs.application.watcher.activated] = "activated",
    [hs.application.watcher.deactivated] = "deactivated",
    [hs.application.watcher.hidden] = "hidden",
    [hs.application.watcher.launched] = "launched",
    [hs.application.watcher.launching] = "launching",
    [hs.application.watcher.terminated] = "terminated",
    [hs.application.watcher.unhidden] = "unhidden",
}

applicationsWatcher = hs.application.watcher.new(function(name, type, _app)
    hs.timer.doAfter(1, function() writeHistory(appEventsHistory, name .. " " .. applcationEventMap[type]) end)
end)

applicationsWatcher:start()

wifiWatcher = hs.wifi.watcher.new(function()
    local currentNetwork
    if hs.wifi.currentNetwork() == nil then
        currentNetwork = "[]"
    else
        currentNetwork = "[" .. hs.wifi.currentNetwork() .. "]"
    end
    local allNetworks = table.concat(hs.wifi.availableNetworks(), ',')

    hs.timer.doAfter(1, function()
        local networks = currentNetwork .. " " .. allNetworks
        writeHistory(wifiFile, networks)
    end)
end)

playbackStateMap = {
    [hs.spotify.state_stopped] = "stopped",
    [hs.spotify.state_paused] = "paused",
    [hs.spotify.state_playing] = "playing",
    [hs.itunes.state_stopped] = "stopped",
    [hs.itunes.state_paused] = "paused",
    [hs.itunes.state_playing] = "playing"
}
function getTrackInfo(itunesOrSpotify)

    return "[" .. playbackStateMap[itunesOrSpotify.getPlaybackState()] .. "] " .. itunesOrSpotify.getCurrentAlbum() .. " " .. itunesOrSpotify.getCurrentArtist() .. " - " .. itunesOrSpotify.getCurrentTrack()
end

hs.timer.doEvery(PERIODICAL_STUFF_INTERVAL_SECONDS, function()
    hs.timer.doAfter(1, function()
        local itunes = getTrackInfo(hs.itunes)
        writeHistory(itunesHistory, itunes)
    end)

    hs.timer.doAfter(2, function()
        local spotify = getTrackInfo(hs.spotify)
        writeHistory(spotifyHistory, spotify)
    end)
end)
