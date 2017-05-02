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
    local dict = {}
    for line in io.lines(file) do
        local words = {}
        for w in line:gmatch("%S+") do table.insert(words, w) end
        if #words == 2 and type(words[1]) == "string" and type(words[1]) == "string" then
            dict[string.lower(words[1])] = words[2]
        end
    end
    return dict
end

local function get_text_file(file)
  if not file_exists(file) then return '' end
  local text_file = io.open(file,'rb')
  local content = text_file:read "*a"
  text_file:close()
  return content
end

local function list_from_file(file)
    -- get all lines from a file with one value per line and return a list type table
    -- return an empty table if the file does not exist
    if not file_exists(file) then return {} end
    local list = {}
    for line in io.lines(file) do
        table.insert(list, line)
    end
    return list
end

local function get_hostname()
    local conf = ubus.call("uci", "get", { config="system", type="system"})
    local result = {}
    local k, sysconf = next(conf.values)
    result.hostname = sysconf.hostname
    result.status = "ok"
    return result
end

local function get_cloud_nodes()
    -- check how to get this data from /tmp/run/bmx6/json
    local conf = ubus.call("uci", "get", { config="network" })
    local local_net = conf.values.lm_net_anygw_route4.target
    local nodes = orange.shell("bmx6 -cd8 | grep ".. local_net .." | awk '{ print $10 }'")
    local result = {}
    result.nodes = {}
    for l in nodes:gmatch("[^\n]*") do
        if l ~= "" then
            table.insert(result.nodes, l)
        end
    end
    result.status = "ok"
    return result
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
        conf = ubus.call("uci", "get", { config="libremap", type="libremap"})
        local k, libremapconf = next(conf.values)
        result.lat = libremapconf.community_lat
        result.lon = libremapconf.community_lon
    end
    result.status = "ok"
    return result
end

local function set_location(params)
    lat = tostring(params.lat)
    lon = tostring(params.lon)
	ubus.call("uci", "set", { config = "libremap", section="location", option="latitude",
                              values={latitude=lat, longitude=lon}})
    local result = ubus.call("uci", "changes", { config = "libremap" })
    ubus.call("uci", "commit", { config = "libremap" })
    result.status = "ok"
    return result
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
    result.status = "ok"
    return result
end

local function get_assoclist(params)
    local iface = params.iface
    local result = {}
    result.stations = {}
    local channel = iwinfo.nl80211.channel(iface)
    local assoclist = iwinfo.nl80211.assoclist(iface)
    local bat_hosts = dict_from_file("/etc/bat-hosts")
    for station_mac, link_data in pairs(assoclist) do
        local wifilink = {
            link_type = "wifi",
            station_mac = station_mac,
            hostname = station_hostname,
            station_hostname = bat_hosts[string.lower(station_mac)] or station_mac,
            attributes = { signal = tostring(link_data.signal),
                           channel = channel, inactive= link_data.inactive }
        }
        table.insert(result.stations, wifilink)
    end
    result.status = "ok"
    return result
end

local function get_station_signal(params)
    local iface = params.iface
    local mac = params.station_mac
    local result = {}
    local assoclist = iwinfo.nl80211.assoclist(iface)
    result.station = mac
    result.signal = tostring(assoclist[mac].signal)
    result.status = "ok"
    return result
end

local function get_iface_stations(params)
    local iface = params.iface
    local result = {}
    local stations = {}
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
        table.insert(stations, station_data)
    end
    result.stations = stations
    result.status = "ok"
    return result
end

local function get_stations(params)
    local ifaces = get_interfaces().interfaces
    local result = {}
    result.stations = {}
    for _, iface  in ipairs(ifaces) do
        iface_stations = get_iface_stations({iface=iface}).stations
        if iface_stations then
            for mac, station in pairs(iface_stations) do
                table.insert(result.stations, station)
            end
        end
    end
    result.status = "ok"
    return result
end

local function get_gateway()
    local result = {}
    local default_dev = orange.shell("ip r | grep 'default dev' | cut -d' ' -f3")
    local shell_output = orange.shell("bmx6 -c show tunnels | grep "..default_dev.."| grep inet4 ")
    local res = {}
    for w in shell_output:gmatch("%S+") do table.insert(res, w) end
    local gw = res[10]
    result.gateway = gw
    result.status = "ok"
    return result
end

local function get_metrics(params)
    local result = {}
    local node = params.target
    local shell_output = orange.shell("ping6 -q  -i 0.1 -c4 -w2 "..node..".mesh")
    local loss = 100
    if shell_output ~= "" then
        local res = {}
        loss = shell_output:match("(%d*)%% packet loss")
    end
    shell_output = orange.shell("netperf -6 -l 2 -H "..node..".mesh| tail -n1| awk '{ print $5 }'")
    local bw = 0
    if shell_output ~= "" then
        bw = shell_output:match("[%d.]+")
    end
    result.loss = loss
    result.bandwidth = bw
    result.status = "ok"
    return result
end

local function get_path(params)
    local node = params.target
    local result = {}
    local path = {}
    local path_str = orange.shell("mtr -6 -r -c 1 " ..node..".mesh  | grep '\.|' |  awk '{ print $2}' | cut -d'.' -f1")
    for l in path_str:gmatch("[^\n]*") do
        if l ~= "" then
            table.insert(path, l)
        end
    end
    result.path = path
    result.status = "ok"
    return result
end

local function get_internet_path_metrics()
    local gw = get_gateway().gateway
    local path = get_path({target=gw}).path
    -- if we cannot establish the current path, we read the last known good one
    if #path==0 then
        path = list_from_file("/tmp/last_internet_path")
    end
    if #path>0 then
        local result = {}
        result.metrics = {}
        for i, node in ipairs(path) do
            local metrics = get_metrics({target=node})
            table.insert(result.metrics, {hop=i, hostname=node, loss=metrics.loss, bandwidth=metrics.bandwidth})
        end
        result.status = "ok"
        return result
    else
        return {status="error", error="no known internet path"}
    end
end

local function write_text_file(file,text)
  if not file_exists(file) then return 0 end
  local text_file = io.open(file,'w')
  text_file:write(text)
  text_file:close()
  return 1
end

local function get_notes()
    local result = {}
    result.notes = get_text_file('/etc/banner.notes')
    result.status = "ok"
    return result
end

local function set_notes(params)
    local result = {}
    local banner = write_text_file('/etc/banner.notes', params.text)
    result = get_notes()
    return result
end

return {
    get_hostname=get_hostname,
    get_location=get_location,
    get_cloud_nodes=get_cloud_nodes,
    set_location=set_location,
    get_interfaces=get_interfaces,
    get_assoclist=get_assoclist,
    get_iface_stations=get_iface_stations,
    get_stations=get_stations,
    get_station_signal=get_station_signal,
    get_gateway=get_gateway,
    get_metrics=get_metrics,
    get_path=get_path,
    get_internet_path_metrics=get_internet_path_metrics,
    get_notes=get_notes,
    set_notes=set_notes
}
