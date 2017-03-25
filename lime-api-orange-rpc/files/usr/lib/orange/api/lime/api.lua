#!/usr/bin/lua
--[[
lime-api-orange-rpc

Copyright 2017 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

local iwinfo = require("iwinfo")
package.path = package.path .. ";/usr/lib/orange/lib/?.lua"
local ubus = require("orange/ubus");
local orange = require("orange/core"); 

local function file_exists(file)
    -- check if the file exists
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

local function dict_from_file(file)
    -- get all lines from a file with two values per line and return a dict type table
    -- return an empty table if the file does not exist
    if not file_exists(file) then return {} end
    dict = {}
    for line in io.lines(file) do
        words = {}
        for w in line:gmatch("%S+") do table.insert(words, w) end
        if #words == 2 and type(words[1]) == "string" and type(words[1]) == "string" then
            dict[string.lower(words[1])] = words[2]
        end
    end
    return dict
end

local function get_hostname()
    local conf = ubus.call("uci", "get", { config="system", type="system"})
    local result = {}
    local k, sysconf = next(conf.values)
    result.hostname = sysconf.hostname
    return result
end

local function get_neighbors()
    -- check how to get this data from /tmp/run/bmx6/json
    local conf = ubus.call("uci", "get", { config="network" })
    local local_net = conf.values.lm_net_anygw_route4.target
    local neighbors = orange.shell("bmx6 -cd8 | grep ".. local_net .." | awk '{ print $10 }'")
    local neigh_table = {}
    for l in neighbors:gmatch("[^\n]*") do
        if l ~= "" then
            table.insert(neigh_table, l)
        end
    end
    return neigh_table
end

local function get_location()
    local result = {}
	local conf = ubus.call("uci", "get", { config = "libremap"})
    local lat = conf.values.location.latitude
    local lon = conf.values.location.longitude
    if (type(tonumber(lat)) == "number" and type(tonumber(lon)) == "number") then
        result.lat = lat
        result.lon = lon
    else
        result.lat = conf.values.settings.community_lat
        result.lon = conf.values.settings.community_lon
    end
    return result
end

local function set_location(params)
    lat = tostring(params.lat)
    lon = tostring(params.lon)
	ubus.call("uci", "set", { config = "libremap", section="location", option="latitude",
                              values={latitude=lat, longitude=lon}})
    changes = ubus.call("uci", "changes", { config = "libremap" })
    ubus.call("uci", "commit", { config = "libremap" })
    return changes
end

local function get_interfaces()
    local conf = ubus.call("uci", "get", { config="wireless", type="wifi-iface"})
    local result = {}
    local ifaces = {}
    for iface,iface_conf in pairs(conf.values) do
        if iface_conf.mode == "adhoc" then
            table.insert(ifaces, iface_conf.ifname)
        end
    end
    result.interfaces = ifaces
    return result
end

local function get_assoclist(params)
    local iface = params.iface
    local result = {}
    local channel = iwinfo.nl80211.channel(iface)
    local assoclist = iwinfo.nl80211.assoclist(iface)
    local bat_hosts = dict_from_file("/etc/bat-hosts")
    for station_mac, link_data in pairs(assoclist) do
        local wifilink = {
            type = "wifi",
            station = station_mac,
            hostname = station_hostname,
            station_hostname = bat_hosts[string.lower(station_mac)] or station_mac,
            attributes = { signal = tostring(link_data.signal),
                           channel = channel, inactive= link_data.inactive }
        }
        result[station_mac] = wifilink
    end
    return result
end

local function get_station_signal(params)
    local iface = params.iface
    local mac = params.station_mac
    local result = {}
    local assoclist = iwinfo.nl80211.assoclist(iface)
    result.station = mac
    result.signal = tostring(assoclist[mac].signal)
    return result
end

local function get_iface_stations(params)
    local iface = params.iface
    local result = {}
    local assoclist = iwinfo.nl80211.assoclist(iface)
    local bat_hosts = dict_from_file("/etc/bat-hosts")
    for mac, link_data in pairs(assoclist) do
        local hostname = bat_hosts[string.lower(mac)] or mac
        local station_data = {
            hostname = hostname,
            mac = mac,
            signal = tostring(link_data.signal),
            iface = iface
        }
        result[mac] = station_data
--        table.insert(result, station_data)
    end
    return result
end

local function get_stations(params)
    local ifaces = get_interfaces().interfaces
    local result = {}
    for _, iface  in ipairs(ifaces) do
        iface_stations = get_iface_stations({iface=iface})
        if iface_stations then
            result[iface] = {}
            for mac, station in pairs(iface_stations) do
                table.insert(result[iface], station)
            end
        end
    end
    return result
end

return {
    get_hostname=get_hostname,
    get_location=get_location,
    get_neighbors=get_neighbors,
    get_bmx6All=get_bmx6,
    set_location=set_location,
    get_interfaces=get_interfaces,
    get_assoclist=get_assoclist,
    get_iface_stations=get_iface_stations,
    get_stations=get_stations,
    get_station_signal=get_station_signal    
}
