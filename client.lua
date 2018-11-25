local parking_prop = "prop_parknmeter_01"
local meters = { }

RegisterCommand("meter", function(source, args)
  local nearMeter = false
  local broken = false
  local pcoords = GetEntityCoords(GetPlayerPed(-1), true)

  local closestParkingMeter = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, 5.0, GetHashKey(parking_prop), false, false, false)

  if (DoesEntityExist(closestParkingMeter)) then
    local meterPos = GetEntityCoords(closestParkingMeter)
    local dist = distance(pcoords, meterPos)

    nearMeter = dist <= 3
    broken = HasObjectBeenBroken(closestParkingMeter)

    if broken then
      sendChatMessage("This parking meter has been broken")
    elseif nearMeter then
      if (args[1] == "pay") then
        meters[closestParkingMeter] = false
        sendChatMessage("You have paid the parking meter.")
      end
    else
      sendChatMessage("You are not near a parking meter.")
    end
  end



end, false)


function distance(posA, posB)
  return Vdist2(posA.x, posA.y, posA.z, posB.x, posB.y, posB.z)
end

function sendChatMessage(text)
  TriggerEvent('chat:addMessage', {
    args = { '^1'..text }
  })
end

function ifContains(set, key)
  return set[key] ~= nil
end
