# 🚗 FiveM Dynamic Fuel System  
**TR / EN: Gerçekçi ve Gelişmiş Yakıt Tüketimi Sistemi**

[🇹🇷 Türkçe açıklama aşağıda | 🇬🇧 English description below]

---

## 🇹🇷 Türkçe Açıklama

### 🔍 Tanım
Bu script, FiveM sunucularında araçların gerçekçi şekilde yakıt tüketmesini sağlayan, dinamik hesaplamalarla çalışan bir sistemdir. Araç hızı, ağırlığı, modifikasyonları ve motor tipi gibi birçok parametreyi dikkate alır.

---

### 🛠️ Export Fonksiyonları

#### `GetFuel(netID)`
Aracın (network ID) güncel yakıt miktarını (litre) verir.

```lua
local netID = VehToNet(GetVehiclePedIsIn(PlayerPedId(), false))
local fuel = exports["dms-fuel_system"]:GetFuel(netID)
print("Yakıt miktarı: ", fuel)
```

#### `SetFuel(netID, amount)`
Aracın yakıt miktarını (litre) ayarlar. Depo kapasitesi aşılamaz.

```
local amount = 100
local netID = VehToNet(GetVehiclePedIsIn(PlayerPedId(), false))
exports["dms-fuel_system"]:SetFuel(netID, amount)
```

#### `GetMaxFuelCapacity(netID)`
Aracın maksimum yakıt deposu kapasitesini döndürür.

```lua
local netID = VehToNet(GetVehiclePedIsIn(PlayerPedId(), false))
local capacity = exports["dms-fuel_system"]:GetMaxFuelCapacity(netID)
print("Depo kapasitesi: ", capacity)
```
---

### ⚙️ Yakıt Tüketimini Etkileyen Unsurlar

| Etken                         | Yaklaşık Etki | Açıklama |
|------------------------------|---------------|----------|
| 🚀 Araç Hızı                 | %20 - %30     | Hız arttıkça tüketim artar |
| 🔁 Motor Devri (RPM)         | %20 - %30     | Yüksek devirde daha fazla tüketim |
| 🧱 Araç Ağırlığı             | %5 - %10      | Ağır araçlar daha fazla tüketir |
| 🛠️ Motor Modifikasyonu      | ~%8 artış     | Her mod seviyesi %2–3 artırır |
| ⚙️ Vites Modifikasyonu      | ~%5 artış     | Performansa göre artış sağlar |
| 💨 Turbo                     | %10 artış     | Turbo açıkken yakıt artar |
| 🛞 Süspansiyon Modifikasyonu| %4’e kadar azalma | Sürtünme azaltılır |
| ⚡ Elektrikli Araçlar        | ~%30 daha verimli | Ayrı formül ile hesaplanır |

---

### ✅ Avantajlar

- Gerçekçi ve detaylı tüketim algoritması
- Elektrikli araçlara özel destek
- Araç modifikasyonlarına duyarlı
- Export destekli ve kolay entegre edilir
- Performans dostu veri takibi

### ⚠️ Sınırlamalar

- Doldurma arayüzü bu scriptte dahil değildir
- Yakıt türleri (benzin/dizel) ayrımı henüz yok
- Kalıcılık (MySQL) eklentisi opsiyoneldir

---

## 🇬🇧 English Description

### 🔍 Description
This script brings dynamic and realistic fuel consumption to your FiveM server. It calculates consumption based on vehicle speed, engine RPM, upgrades, weight, and type. It also includes support for electric vehicles.

---

### 🛠️ Export Functions

#### `GetFuel(netID)`
Returns the current fuel level (in liters) of a vehicle by its network ID.

```lua
local netID = VehToNet(GetVehiclePedIsIn(PlayerPedId(), false))
local fuel = exports["dms-fuel_system"]:GetFuel(netID)
print("Yakıt miktarı: ", fuel)
```

#### `SetFuel(netID, amount)`
Sets the fuel level (in liters) of the vehicle. It is clamped to the vehicle’s maximum capacity.

```
local amount = 100
local netID = VehToNet(GetVehiclePedIsIn(PlayerPedId(), false))
exports["dms-fuel_system"]:SetFuel(netID, amount)
```

#### `GetMaxFuelCapacity(netID)`
Returns the maximum fuel tank capacity for a given vehicle.

```lua
local netID = VehToNet(GetVehiclePedIsIn(PlayerPedId(), false))
local capacity = exports["dms-fuel_system"]:GetMaxFuelCapacity(netID)
print("Depo kapasitesi: ", capacity)
```
---

### ⚙️ Factors That Affect Fuel Consumption

| Factor                       | Approx. Impact | Description |
|-----------------------------|----------------|-------------|
| 🚀 Vehicle Speed            | 20% - 30%      | More speed = more fuel used |
| 🔁 Engine RPM               | 20% - 30%      | Higher RPM = more fuel |
| 🧱 Vehicle Mass             | 5% - 10%       | Heavier = more consumption |
| 🛠️ Engine Mods             | ~8% increase   | Each level increases 2–3% |
| ⚙️ Gearbox Mods            | ~5% increase   | Slight increase |
| 💨 Turbo Enabled           | +10%           | Turbo causes extra consumption |
| 🛞 Suspension Mods         | Up to -4%      | Can reduce consumption |
| ⚡ Electric Vehicles        | ~30% more efficient | Uses separate formula |

---

### ✅ Advantages

- Realistic and advanced fuel consumption
- Electric vehicle support
- Upgrade-sensitive logic
- Fully exportable and integrable
- Lightweight and optimized for performance

### ⚠️ Limitations

- No fuel UI or refill interface (can be integrated)
- No gasoline/diesel type distinction yet
- Optional MySQL integration (can be added)

---

## 🔧 Integration Tips

- Connect HUD to `GetFuel` for real-time display
- Use `SetFuel` in gas station scripts
- `GetMaxFuelCapacity` helps prevent overfilling

---

## 📄 License
MIT — Free to use, modify, and distribute. Credit is appreciated but not required.

---

## 🤝 Contribute
Issues and pull requests are welcome. Let’s improve this together!

> Script by **Delarmuss** — [@Delarmuss](https://github.com/delarmuss)
