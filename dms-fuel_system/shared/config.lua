Config = {}

Config.UseDrawText = true

-- The recommended capacity value for trucks, buses, etc. is 120 consumption is 2.0
Config.vehicleClass = {
  [0] = { consumption = 1.0, tankCapacity = 40.0 },   -- Compact
  [1] = { consumption = 1.0, tankCapacity = 50.0 },   -- Sedan
  [2] = { consumption = 1.1, tankCapacity = 70.0 },   -- SUV
  [3] = { consumption = 1.3, tankCapacity = 50.0 },   -- Coupe
  [4] = { consumption = 1.4, tankCapacity = 60.0 },   -- Muscle
  [5] = { consumption = 1.5, tankCapacity = 55.0 },   -- Sports Classic
  [6] = { consumption = 1.6, tankCapacity = 55.0 },   -- Sports
  [7] = { consumption = 1.8, tankCapacity = 45.0 },   -- Super
  [8] = { consumption = 1.2, tankCapacity = 20.0 },   -- Motorcycle
  [9] = { consumption = 1.3, tankCapacity = 75.0 },   -- Offroad
  [10] = { consumption = 2.5, tankCapacity = 120.0 }, -- Industrial
  [11] = { consumption = 2.2, tankCapacity = 70.0 },  -- Utility
  [12] = { consumption = 2.0, tankCapacity = 80.0 },  -- Vans
  [13] = { consumption = 0.0, tankCapacity = 0.0 },   -- Cycle (Bisiklet, yakıt yok)
  [14] = { consumption = 2.5, tankCapacity = 80.0 },  -- Boat
  [15] = { consumption = 2.5, tankCapacity = 80.0 },  -- Helicopter
  [16] = { consumption = 3.5, tankCapacity = 250.0 }, -- Planes
  [17] = { consumption = 3.0, tankCapacity = 120.0 }, -- Service (Servis araçları için orta seviye)
  [18] = { consumption = 1.0, tankCapacity = 60.0 },  -- Emergency
  [19] = { consumption = 2.0, tankCapacity = 120.0 }, -- Military
  [20] = { consumption = 2.0, tankCapacity = 120.0 }, -- Commercial
  [21] = { consumption = 0.0, tankCapacity = 0.0 },   -- Train (Tren, yakıt yok)
  [22] = { consumption = 1.8, tankCapacity = 45.0 },  -- Open Wheel
}

Config.defaultTankCapacity = 50.0
Config.vehicles = {
  [`bulldozer`] = { consumption = 2.5, tankCapacity = 250.0 },
  [`cutter`] = { consumption = 2.5, tankCapacity = 250.0 },
  [`dump`] = { consumption = 2.5, tankCapacity = 250.0 },
  [`handler`] = { consumption = 2.5, tankCapacity = 250.0 },
  [`taxi`] = { consumption = 1.0, tankCapacity = 60.0 },
  [`tourbus`] = { consumption = 2.0, tankCapacity = 80.0 },
  [`rentalbus`] = { consumption = 2.0, tankCapacity = 80.0 },
  [`ambulance`] = { consumption = 2.0, tankCapacity = 80.0 },
  [`firetruk`] = { consumption = 2.0, tankCapacity = 120.0 },
  [`pbus`] = { consumption = 2.0, tankCapacity = 120.0 },
  [`policeb`] = { consumption = 1.2, tankCapacity = 30.0 },
  [`riot`] = { consumption = 2.0, tankCapacity = 120.0 },
  [`riot2`] = { consumption = 2.0, tankCapacity = 120.0 },
}
