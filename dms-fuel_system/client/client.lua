local vehicleFuelData = {}
local vehicleUpdateTime = {}

Citizen.CreateThread(function()
  DecorRegister("unique_fuel_id", 3) -- 3 = INT
end)

function getVehicleUUID(vehicle)
  if not DoesEntityExist(vehicle) then return nil end

  if not DecorExistOn(vehicle, "unique_fuel_id") then
    local id = math.random(1000000, 9999999)
    DecorSetInt(vehicle, "unique_fuel_id", id)
  end

  return tostring(DecorGetInt(vehicle, "unique_fuel_id"))
end

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

  local vehicleConfig = Config.vehicles[modelHash]
  local class = GetVehicleClass(vehicle)
  local classData = Config.vehicleClass[class] or { consumption = 1.0, tankCapacity = Config.defaultTankCapacity }

  local consumptionRate = vehicleConfig and vehicleConfig.consumption or classData.consumption

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

local function getTankCapacity(vehicle)
  local modelHash = GetEntityModel(vehicle)
  local vehicleConfig = Config.vehicles[modelHash]
  if vehicleConfig and vehicleConfig.tankCapacity then
    return vehicleConfig.tankCapacity
  end
  local class = GetVehicleClass(vehicle)
  local classData = Config.vehicleClass[class] or { tankCapacity = Config.defaultTankCapacity }
  return classData.tankCapacity
end

function GetMaxFuelCapacity(vehicle)
  if DoesEntityExist(vehicle) then
    return getTankCapacity(vehicle)
  else
    return Config.defaultTankCapacity
  end
end

function GetFuel(vehicle)
  local uuid = getVehicleUUID(vehicle)
  if not uuid then return nil end
  return vehicleFuelData[uuid]
end

function SetFuel(vehicle, amount)
  if not DoesEntityExist(vehicle) then return end
  local uuid = getVehicleUUID(vehicle)
  if not uuid then return end

  local maxFuel = GetMaxFuelCapacity(vehicle)
  local clampedAmount = math.min(math.max(amount, 0), maxFuel)

  vehicleFuelData[uuid] = clampedAmount
  vehicleUpdateTime[uuid] = GetGameTimer()
  SetVehicleFuelLevel(vehicle, clampedAmount)
  TriggerServerEvent("vehicle:updateFuel", uuid, clampedAmount)
end

Citizen.CreateThread(function()
  exports("GetFuel", GetFuel)
  exports("SetFuel", SetFuel)
  exports("GetMaxFuelCapacity", GetMaxFuelCapacity)
end)

RegisterNetEvent("vehicle:setFuel")
AddEventHandler("vehicle:setFuel", function(uuid, fuelAmount)
  vehicleFuelData[uuid] = fuelAmount
  vehicleUpdateTime[uuid] = GetGameTimer()

  -- Oyuncunun içindeki araç o UUID'ye aitse, yakıt seviyesini anında uygula
  local ped = PlayerPedId()
  local vehicle = GetVehiclePedIsIn(ped, false)
  if vehicle and DoesEntityExist(vehicle) and getVehicleUUID(vehicle) == uuid then
    SetVehicleFuelLevel(vehicle, fuelAmount)
  end
end)

local function requestFuelForVehicle(uuid)
  TriggerServerEvent("vehicle:requestFuel", uuid)
end

local lastServerUpdateTime = {}
local lastServerFuelSent = {}

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(500)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
      local vehicle = GetVehiclePedIsIn(ped, false)
      if vehicle and DoesEntityExist(vehicle) then
        local uuid = getVehicleUUID(vehicle)
        local maxFuel = GetMaxFuelCapacity(vehicle)
        if maxFuel == 0.0 then goto continueLoop end

        if not vehicleFuelData[uuid] then
          requestFuelForVehicle(uuid)
        end

        local currentFuel = vehicleFuelData[uuid] or maxFuel

        if GetIsVehicleEngineRunning(vehicle) then
          local currentTime = GetGameTimer()
          local lastTime = vehicleUpdateTime[uuid] or currentTime
          local deltaTime = (currentTime - lastTime) / 1000.0
          local consumption = calculateFuelConsumptionAdvanced(vehicle)

          currentFuel = math.max(0.0, math.min(currentFuel - (consumption * deltaTime), maxFuel))
          vehicleFuelData[uuid] = currentFuel
          vehicleUpdateTime[uuid] = currentTime
          SetVehicleFuelLevel(vehicle, currentFuel)

          local lastSentTime = lastServerUpdateTime[uuid] or 0
          local lastFuelSent = lastServerFuelSent[uuid] or (currentFuel + 1)
          local timeSinceLastSend = (currentTime - lastSentTime) / 1000.0
          local fuelDifference = math.abs(currentFuel - lastFuelSent)

          if timeSinceLastSend >= 1.0 or fuelDifference >= 0.1 then
            TriggerServerEvent("vehicle:updateFuel", uuid, currentFuel)
            lastServerUpdateTime[uuid] = currentTime
            lastServerFuelSent[uuid] = currentFuel
          end
        else
          vehicleUpdateTime[uuid] = GetGameTimer()
        end
        ::continueLoop::
      end
    else
      Citizen.Wait(1000)
    end
  end
end)

if Config.UseDrawText then
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
        local maxFuel = GetMaxFuelCapacity(vehicle)
        if maxFuel > 0.0 then
          local fuel = GetFuel(vehicle) or maxFuel
          drawText(0.015, 0.92, ("Fuel: %.1f / %.1f L"):format(fuel, maxFuel), 0.4, 255, 255, 255)
        end
      end
    end
  end)
end
