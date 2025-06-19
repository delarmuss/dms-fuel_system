local vehicleFuelData = {}
local vehicleUpdateTime = {}

-- Elektrikli araç kontrolü
local function isElectricVehicle(vehicle)
  local model = GetEntityModel(vehicle)
  return GetIsVehicleElectric(model)
end

-- Mod oranlarını hesapla
local function getModRatio(vehicle, modType)
  local modLevel = GetVehicleMod(vehicle, modType)
  local maxMods = GetNumVehicleMods(vehicle, modType)
  if modLevel == -1 or maxMods == 0 then return 0.0 end
  return (modLevel + 1) / (maxMods + 1)
end

-- Gelişmiş tüketim hesaplama
local function calculateFuelConsumptionAdvanced(vehicle)
  if not GetIsVehicleEngineRunning(vehicle) then return 0.0 end

  local speed = GetEntitySpeed(vehicle) * 3.6
  local rpm = GetVehicleCurrentRpm(vehicle)
  local mass = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fMass")
  local driveForce = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce")
  local electric = isElectricVehicle(vehicle)
  local modelHash = GetEntityModel(vehicle)

  -- Model bazlı varsa öncelikli al
  local vehicleConfig = Config.vehicles[modelHash]
  local class = GetVehicleClass(vehicle)
  local classData = Config.vehicleClass[class] or { consumption = 1.0, tankCapacity = Config.defaultTankCapacity }

  local consumptionRate = vehicleConfig and vehicleConfig.consumption or classData.consumption

  -- Mod oranları vs (aynı kalabilir)
  local engineRatio = getModRatio(vehicle, 11)
  local gearboxRatio = getModRatio(vehicle, 13)
  local suspensionRatio = getModRatio(vehicle, 15)
  local turboOn = IsToggleModOn(vehicle, 18)

  local engineMultiplier = 1.0 + (engineRatio * 0.08)
  local gearboxMultiplier = 1.0 + (gearboxRatio * 0.06)
  local turboMultiplier = turboOn and 1.1 or 1.0
  local suspensionMultiplier = 1.0 - (suspensionRatio * 0.04)

  local upgradeMultiplier = engineMultiplier * gearboxMultiplier * turboMultiplier * suspensionMultiplier
  local massImpact = (speed < 50) and (mass / 6000) or (mass / 10000)

  local engineHealth = GetVehicleEngineHealth(vehicle)
  local damageMultiplier = 1.0 + ((1000.0 - engineHealth) / 1000.0) * 0.5

  local isMoving = speed > 5.0
  local finalUpgradeMultiplier = isMoving and upgradeMultiplier or 1.0

  local baseConsumption = electric
      and ((speed * 0.015) + (rpm * 0.07) + massImpact + (driveForce * 0.8)) * 0.008
      or ((speed * 0.02) + (rpm * 0.08) + massImpact + (driveForce * 1.0)) * 0.01

  return baseConsumption * consumptionRate * finalUpgradeMultiplier * damageMultiplier
end

-- Tank kapasitesi (model -> sınıf)
local function getTankCapacity(vehicle)
  local modelHash = GetEntityModel(vehicle)

  local vehicleConfig = Config.vehicles[modelHash]
  if vehicleConfig and vehicleConfig.tankCapacity then
    if vehicleConfig.tankCapacity == 0.0 then
      return 0.0
    else
      return vehicleConfig.tankCapacity
    end
  end

  local class = GetVehicleClass(vehicle)
  local classData = Config.vehicleClass[class] or { tankCapacity = Config.defaultTankCapacity }

  if classData.tankCapacity == 0.0 then
    return 0.0
  else
    return classData.tankCapacity
  end
end

-- Export: Maksimum kapasite
function GetMaxFuelCapacity(netID)
  local vehicle = NetToVeh(netID)
  if DoesEntityExist(vehicle) then
    return getTankCapacity(vehicle)
  else
    return Config.defaultTankCapacity
  end
end

-- Export: Yakıt al
function GetFuel(netID)
  return vehicleFuelData[netID] or nil
end

-- Export: Yakıt ayarla
function SetFuel(netID, amount)
  local vehicle = NetToVeh(netID)
  if DoesEntityExist(vehicle) then
    local maxFuel = GetMaxFuelCapacity(netID)
    local clampedAmount = math.min(math.max(amount, 0), maxFuel)
    vehicleFuelData[netID] = clampedAmount
    vehicleUpdateTime[netID] = GetGameTimer()
    SetVehicleFuelLevel(vehicle, clampedAmount)
    TriggerServerEvent("vehicle:updateFuel", netID, clampedAmount)
  end
end

-- Export'ları dışarıya aç
Citizen.CreateThread(function()
  exports("GetFuel", GetFuel)
  exports("SetFuel", SetFuel)
  exports("GetMaxFuelCapacity", GetMaxFuelCapacity)
end)

-- Server'dan yakıt al
RegisterNetEvent("vehicle:setFuel")
AddEventHandler("vehicle:setFuel", function(netVehicleId, fuelAmount)
  local vehicle = NetToVeh(netVehicleId)
  if DoesEntityExist(vehicle) then
    SetVehicleFuelLevel(vehicle, fuelAmount)
    vehicleFuelData[netVehicleId] = fuelAmount
    vehicleUpdateTime[netVehicleId] = GetGameTimer()
  end
end)

local function requestFuelForVehicle(netID)
  TriggerServerEvent("vehicle:requestFuel", netID)
end

-- Ana yakıt güncelleme döngüsü
local lastServerUpdateTime = {}
local lastServerFuelSent = {}

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(500)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
      local vehicle = GetVehiclePedIsIn(ped, false)
      if vehicle and vehicle ~= 0 then
        local netID = VehToNet(vehicle)
        local maxFuel = GetMaxFuelCapacity(netID)
        if maxFuel == 0.0 then
          -- Bu araçta yakıt sistemi yok, işlem yapma
          goto continueLoop
        end

        if vehicleFuelData[netID] == nil then
          requestFuelForVehicle(netID)
        end

        local currentFuel = vehicleFuelData[netID] or maxFuel

        if currentFuel <= 0 then
          currentFuel = 0
        end

        if GetIsVehicleEngineRunning(vehicle) then
          local currentTime = GetGameTimer()
          local lastTime = vehicleUpdateTime[netID] or currentTime
          local deltaTime = (currentTime - lastTime) / 1000.0
          local consumption = calculateFuelConsumptionAdvanced(vehicle)

          currentFuel = currentFuel - (consumption * deltaTime)
          if currentFuel < 0 then currentFuel = 0 end
          if currentFuel > maxFuel then currentFuel = maxFuel end

          vehicleFuelData[netID] = currentFuel
          vehicleUpdateTime[netID] = currentTime

          SetVehicleFuelLevel(vehicle, currentFuel)

          -- Event gönderme optimizasyonu
          local lastSentTime = lastServerUpdateTime[netID] or 0
          local lastFuelSent = lastServerFuelSent[netID] or currentFuel + 1 -- Fark olsun diye
          local timeSinceLastSend = (currentTime - lastSentTime) / 1000.0
          local fuelDifference = math.abs(currentFuel - lastFuelSent)

          if timeSinceLastSend >= 1.0 or fuelDifference >= 0.1 then
            TriggerServerEvent("vehicle:updateFuel", netID, currentFuel)
            lastServerUpdateTime[netID] = currentTime
            lastServerFuelSent[netID] = currentFuel
          end
        else
          vehicleUpdateTime[netID] = GetGameTimer()
        end
        ::continueLoop::
      end
    else
      Citizen.Wait(1000)
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(30000) -- Her 30 saniyede bir kontrol

    for netID, _ in pairs(vehicleFuelData) do
      if not NetworkDoesNetworkIdExist(netID) then
        vehicleFuelData[netID] = nil
        vehicleUpdateTime[netID] = nil
      end
    end
  end
end)

if Config.UseDrawText then
  -- Yakıt göstergesi
  local function drawText(x, y, text, scale, r, g, b, a)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a or 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
  end

  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)
      local ped = PlayerPedId()
      if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local netID = VehToNet(vehicle)
        local fuel = GetFuel(netID) or GetMaxFuelCapacity(netID)
        local maxFuel = GetMaxFuelCapacity(netID)
        if maxFuel > 0.0 then
          local fuel = GetFuel(netID) or maxFuel
          drawText(0.015, 0.92, ("Fuel: %.1f / %.1f L"):format(fuel, maxFuel), 0.4, 255, 255, 255)
        end
      end
    end
  end)
end
