local max_park_time = 10 -- Minutes

local parking_prop = "prop_parknmeter_01"
local meters = { }
local time = 0
local closemeter = nil
local pcoords = nil
local debug = true

-- TIMER

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1000)
    time = time + 1
  end
end)

-- MAIN LOOP

Citizen.CreateThread(function()
  while true do
    local ped = GetPlayerPed(-1)
    pcoords = GetEntityCoords(ped)

    closemeter = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, 10.0, GetHashKey(parking_prop), false, false, false)
    local meterPos = GetEntityCoords(closemeter)
    local broken = HasObjectBeenBroken(closemeter)
    if distance(meterPos, pcoords) < 20 then
      if contains(meters, meterPos) then
        if not broken then
          local countdown = round(timeRemaining(meters[meterPos])/60, 1)

          if countdown > 0 then
            DrawMeterStatus(meterPos, "~p~"..countdown.." minutes")
          else
            TriggerServerEvent("parkingmeter:cancelmeter", meterPos)
            Citizen.Wait(1000)
          end
        else
          TriggerServerEvent("parkingmeter:cancelmeter", meterPos)
          Citizen.Wait(1000)
        end
      else
        --DrawMeterStatus(objectCoordsDraw, "~g~Vacant")
      end
    end
    Citizen.Wait(0)
  end
end)

-- METER COMMAND

RegisterCommand("meter", function(source, args)
  local subcommand = args[1]

  if (DoesEntityExist(closemeter)) then
    local meterPos = GetEntityCoords(closemeter)
    local dist = distance(pcoords, meterPos)

    nearMeter = dist < 5
    broken = HasObjectBeenBroken(closemeter)

    if broken then
      sendChatMessage("This parking meter has been broken")
    elseif nearMeter then
      if not (subcommand) then

      elseif (subcommand == "pay") then
        sendChatMessage("You have paid the parking meter.")
        TriggerServerEvent("parkingmeter:activatemeter", meterPos)
        debugLog(meterPos)

      elseif (subcommand == "cancel") then
        --meters = table.removeKey(meters, meterPos)
        TriggerServerEvent("parkingmeter:cancelmeter", meterPos)
      end
    else
      sendChatMessage("You are not near a parking meter.")
    end
  end
end, false)


-- EVENTS

RegisterNetEvent("parkingmeter:timesync")
AddEventHandler("parkingmeter:timesync", function(server_time)
  debugLog("Received time sync: " .. server_time .. " (our client time was " .. time .. ")")
  time = server_time
end)

RegisterNetEvent("parkingmeter:update")
AddEventHandler("parkingmeter:update", function(server_meters, server_orientations)
  debugLog("Received meter update")
  meters = server_meters
end)

AddEventHandler("playerSpawned", function()
  TriggerServerEvent("parkingmeter:requestsync")
end)


-- HELPER FUNCTIONS

function debugLog(message)
  if debug then
    Citizen.Trace("PARKINGMETER DEBUG: " .. message)
  end
end

function timeRemaining(time_parked_at)
  return max_park_time*60-(time-time_parked_at)
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function distance(posA, posB)
  return Vdist2(posA.x, posA.y, posA.z, posB.x, posB.y, posB.z)
end

function DrawMeterStatus(meter, text)
  DrawText3D(meter.x, meter.y, meter.z + 1.4, text)
end

-- Code from koil: https://forum.fivem.net/t/draw-text-though-the-walls/53398/18
function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(0.4, 0.4)
        SetTextFont(0)
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 55)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

function sendChatMessage(text)
  TriggerEvent("chat:addMessage", {
    args = { "^1"..text }
  })
end

function drawNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(false, false)
end

function getRaycastMatrix(meterpos, rotation)
  local meterpos = meterpos
  local scannerpos = vector3(meterpos.x, meterpos.y, meterpos.z+0.8)
  return scannerpos, scannerpos+rotation*2.6
end

function contains(set, key)
  return set[key] ~= nil
end
