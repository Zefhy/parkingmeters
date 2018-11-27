local time = 0
local sync_rate = 60000
local meter_times = { }
local debug = true

-- Timer
Citizen.CreateThread(function()
  while true do
    time = time + 1
    Citizen.Wait(1000)
  end
end)

-- Keep client times up to date
Citizen.CreateThread(function()
  while true do
    debugLog("Sent timesync at "..time)
    TriggerClientEvent("parkingmeter:timesync", -1, time)
    Citizen.Wait(sync_rate)
  end
end)

RegisterNetEvent("parkingmeter:requestsync")
AddEventHandler("parkingmeter:requestsync", function()
  debugLog("Received sync request from " .. source)
  TriggerClientEvent("parkingmeter:timesync", source, time)
end)

RegisterNetEvent("parkingmeter:activatemeter")
AddEventHandler("parkingmeter:activatemeter", function(meter, orientation)
  debugLog("Received meter activation: " .. meter .. " @ " .. time)
  meter_times[meter] = time
  TriggerClientEvent("parkingmeter:update", -1, meter_times)
end)

RegisterNetEvent("parkingmeter:cancelmeter")
AddEventHandler("parkingmeter:cancelmeter", function(meter)
  debugLog("Received meter cancellation: " .. meter)
  meter_times = table.removeKey(meter_times, meter)
  TriggerClientEvent("parkingmeter:update", -1, meter_times)
end)

function debugLog(message)
  if debug then
    Citizen.Trace("PARKINGMETER DEBUG: " .. message .. "\n")
  end
end

function table.removeKey(t, k)
	local i = 0
	local keys, values = {},{}
	for k,v in pairs(t) do
		i = i + 1
		keys[i] = k
		values[i] = v
	end

	while i>0 do
		if keys[i] == k then
			table.remove(keys, i)
			table.remove(values, i)
			break
		end
		i = i - 1
	end

	local a = {}
	for i = 1,#keys do
		a[keys[i]] = values[i]
	end

	return a
end
