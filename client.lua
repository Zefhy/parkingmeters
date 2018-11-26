local max_park_time = 30 -- Minutes

local parking_prop = "prop_parknmeter_01"
local meters = { }
local time = 0
local closemeter = nil
local pcoords = nil

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
    pcoords = GetEntityCoords(GetPlayerPed(-1))
    closemeter = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, 10.0, GetHashKey(parking_prop), false, false, false)
    local objectCoordsDraw = GetEntityCoords(closemeter)

    if distance(objectCoordsDraw, pcoords) < 5 then
      if not HasObjectBeenBroken(closemeter) then
        if contains(meters, closemeter) then
          local countdown = round(timeRemaining(meters[closemeter])/60, 1)
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

        if contains(meters, closemeter) then
          local time_parked_at = meters[closemeter]
          if time - time_parked_at > max_park_time*60 then
            sendChatMessage("OH MY GOD RUN")
          else
            sendChatMessage("Time remaining (minutes): " .. round(timeRemaining(time_parked_at)/60, 1))
          end
        else
          sendChatMessage("This is a parking meter, you may park here for a maximum of "..max_park_time.." minutes. Failure to pay will result in a ticket!")
        end

      elseif (subcommand == "pay") then
        --print(contains(meters, closemeter))
        sendChatMessage("You have paid the parking meter.")
        meters[closemeter] = time
      elseif (subcommand == "cancel") then
        meters = table.removeKey(meters, closemeter)
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

function contains(set, key)
  return set[key] ~= nil
end
