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
