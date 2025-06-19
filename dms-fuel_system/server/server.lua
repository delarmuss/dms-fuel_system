local vehicleFuelData = {}

RegisterNetEvent("vehicle:updateFuel")
AddEventHandler("vehicle:updateFuel", function(netVehicleId, fuelAmount)
  vehicleFuelData[netVehicleId] = fuelAmount

  -- Tüm oyunculara güncel yakıt bilgisini yay
  TriggerClientEvent("vehicle:setFuel", -1, netVehicleId, fuelAmount)

  -- Buraya MySQL güncellemesi istersen eklenebilir
end)

-- İsteğe bağlı: Client yeni araca bindiğinde yakıtını isteyebilir
RegisterNetEvent("vehicle:requestFuel")
AddEventHandler("vehicle:requestFuel", function(netVehicleId)
  local src = source
  local fuel = vehicleFuelData[netVehicleId] or 100.0
  TriggerClientEvent("vehicle:setFuel", src, netVehicleId, fuel)
end)
