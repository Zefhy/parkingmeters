local time = 0
local sync_rate = 60000

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
