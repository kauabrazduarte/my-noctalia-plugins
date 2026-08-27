--!nonstrict
-- Headless service: polls sysfs every 2s and publishes the battery state on
-- the plugin's shared state. BarWidget and the shortcut entry watch this.

local function read(path)
  local f = io.open(path, "r")
  if f == nil then return nil end
  local v = f:read("*l")
  f:close()
  if v == nil then return nil end
  return (v:gsub("%s+", ""))
end

local function poll()
  -- The real source of truth for the charge mode is conservation_mode.
  -- charge_types is read-only; its bracketed value mirrors what conservation_mode says.
  local cons = read("/sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode") or "0"
  local mode = (cons == "1") and "Long_Life" or "Standard"

  local cap = tonumber(read("/sys/class/power_supply/BAT0/capacity") or "?")
  local status = read("/sys/class/power_supply/BAT0/status") or "?"
  local charging = (status == "Charging") or (status == "Full")

  noctalia.state.set("battery", {
    mode = mode,
    capacity = cap,
    charging = charging,
    status = status,
  })
end

-- Initial render + tick every 2s
poll()
noctalia.setUpdateInterval(2000)
function update()
  poll()
end
