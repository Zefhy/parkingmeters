local max_park_time = 10/60 -- Minutes

local parking_prop = "prop_parknmeter_01"
local meters = { }
local meter_orientations = { }
local time = 0
local closemeter = nil
local pcoords = nil
local vehicleInSpace = nil
local orientation = nil

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
    local objectCoordsDraw = GetEntityCoords(closemeter)

    if distance(objectCoordsDraw, pcoords) < 20 then
      if not HasObjectBeenBroken(closemeter) then

        orientation = vector3(GetEntityForwardX(ped), GetEntityForwardY(ped), -0.1)
        local start, forwardVector = getRaycastMatrix(objectCoordsDraw, orientation)
        --DrawLine(start, forwardVector, 255,0,0,255)

        local rayHandle = CastRayPointToPoint(start,forwardVector, 10, nil, 0)
        local _, _, _, _, targetVehicle = GetRaycastResult(rayHandle)
        if targetVehicle ~= nil then
          if DoesEntityExist(targetVehicle) then
            vehicleInSpace = targetVehicle
          else
            vehicleInSpace = nil
          end
        end

        if contains(meters, objectCoordsDraw) and contains(meter_orientations, objectCoordsDraw) then
          local countdown = round(timeRemaining(meters[objectCoordsDraw])/60, 1)

          local start, forwardVector = getRaycastMatrix(objectCoordsDraw, meter_orientations[objectCoordsDraw])
          local rayHandle = CastRayPointToPoint(start,forwardVector, 10, nil, 0)
          local _, _, _, _, targetVehicle = GetRaycastResult(rayHandle)
          DrawLine(start, forwardVector, 255,0,0,255)

          if targetVehicle == 0 then
            -- Reset the meter!!!
            TriggerServerEvent("parkingmeter:cancelmeter", objectCoordsDraw)
            Citizen.Wait(1000) -- Wait so we don't send multiple cancellations
          end
          
          if countdown > 0 then
            DrawMeterStatus(objectCoordsDraw, "~g~"..countdown.." minutes")
          else
            DrawMeterStatus(objectCoordsDraw, "~r~EXPIRED")
          end
        else
          DrawMeterStatus(objectCoordsDraw, "~g~Vacant")
        end
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
        if vehicleInSpace then
          --print(contains(meters, closemeter))
          sendChatMessage("You have paid the parking meter.")
          TriggerServerEvent("parkingmeter:activatemeter", meterPos, orientation)
          Citizen.Trace(meterPos)
        else
          sendChatMessage("No vehicle detected.")
        end

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
  Citizen.Trace("Received time sync: " .. server_time .. " (our client time was " .. time .. ")")
  time = server_time
end)

RegisterNetEvent("parkingmeter:update")
AddEventHandler("parkingmeter:update", function(server_meters, server_orientations)
  Citizen.Trace("Received meter update")
  meters = server_meters
  meter_orientations = server_orientations
end)

AddEventHandler("playerSpawned", function()
  TriggerServerEvent("parkingmeter:requestsync")
end)


-- HELPER FUNCTIONS

-- Remove key k (and its value) from table t. Return a new (modified) table.
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

function getRaycastMatrix(meterpos, rotation)
  local meterpos = meterpos
  local scannerpos = vector3(meterpos.x, meterpos.y, meterpos.z+0.8)
  return scannerpos, scannerpos+rotation*2.6
end

function contains(set, key)
  return set[key] ~= nil
end
