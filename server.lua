local time = 0
local sync_rate = 60000
local meter_times = { }
local meter_orientations = { }

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
    Citizen.Trace("Sent timesync at "..time)
    TriggerClientEvent("parkingmeter:timesync", -1, time)
    Citizen.Wait(sync_rate)
  end
end)

RegisterNetEvent("parkingmeter:requestsync")
AddEventHandler("parkingmeter:requestsync", function()
  Citizen.Trace("Received sync request from " .. source)
  TriggerClientEvent("parkingmeter:timesync", source, time)
end)

RegisterNetEvent("parkingmeter:activatemeter")
AddEventHandler("parkingmeter:activatemeter", function(meter, orientation)
  Citizen.Trace("Received meter activation: " .. meter .. " @ " .. time .. " facing " .. orientation)
  meter_times[meter] = time
  meter_orientations[meter] = orientation
  TriggerClientEvent("parkingmeter:update", -1, meter_times, meter_orientations)
end)

RegisterNetEvent("parkingmeter:cancelmeter")
AddEventHandler("parkingmeter:cancelmeter", function(meter)
  Citizen.Trace("Received meter cancellation: " .. meter)
  meter_times = table.removeKey(meter_times, meter)
  meter_orientations = table.removeKey(meter_orientations, meter)
  TriggerClientEvent("parkingmeter:update", -1, meter_times, meter_orientations)
end)

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
