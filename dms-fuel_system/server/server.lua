local vehicleFuelData = {}

RegisterNetEvent("vehicle:updateFuel", function(uuid, fuelAmount)
  if type(uuid) ~= "string" or type(fuelAmount) ~= "number" then return end
  if fuelAmount < 0 or fuelAmount > 250 then return end

  vehicleFuelData[uuid] = fuelAmount

  -- Tüm oyunculara güncel yakıt bilgisini gönder
  TriggerClientEvent("vehicle:setFuel", -1, uuid, fuelAmount)

  -- İsteğe bağlı: Kalıcı veri tabanına yazmak istersen buraya ekleyebilirsin
end)

RegisterNetEvent("vehicle:requestFuel", function(uuid)
  local src = source
  if type(uuid) ~= "string" then return end

  local fuel = vehicleFuelData[uuid] or Config.defaultTankCapacity
  TriggerClientEvent("vehicle:setFuel", src, uuid, fuel)
end)
