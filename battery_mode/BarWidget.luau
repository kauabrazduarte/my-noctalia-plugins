--!nonstrict
-- Battery charge mode bar widget.
-- Reads shared state published by service.luau and renders the current mode
-- (Standard / Long_Life) plus the live capacity. Click toggles via pkexec + TLP.

local showLabel = noctalia.getConfig("show_label")
local clickToToggle = noctalia.getConfig("click_to_toggle")

local state = noctalia.state.get("battery") or {}
local mode = state.mode or "Long_Life"
local capacity = state.capacity or 0
local charging = state.charging or false

local function render()
  -- Glyph varies by state: bolt (Standard/charging) or leaf (Long_Life).
  if mode == "Standard" then
    barWidget.setGlyph("bolt")
  else
    barWidget.setGlyph("leaf")
  end
  if showLabel then
    barWidget.setText(tostring(capacity) .. "%")
  end
  -- Tooltip: full status (translated)
  local statusKey = charging and "tooltip.charging" or "tooltip.discharging"
  local modeKey = (mode == "Standard") and "tooltip.standard" or "tooltip.longlife"
  barWidget.setTooltip(noctalia.tr("title") .. " — " .. capacity .. "% • " ..
                       noctalia.tr(statusKey) .. " • " .. noctalia.tr(modeKey))
end

noctalia.state.watch("battery", function(value)
  if value ~= nil then
    state = value
    mode = state.mode or mode
    capacity = state.capacity or capacity
    charging = state.charging or charging
    render()
  end
end)

-- Click toggles between Standard and Long_Life. We use Quickshell.execDetached
-- to run pkexec + tlp so the bar widget stays responsive while the auth dialog
-- is up. The service will pick up the new mode on its next tick.
function onClick()
  if not clickToToggle then return end
  local target = (mode == "Standard") and "poupar" or "cheia"
  Quickshell.execDetached({
    "fish", "-c",
    "bat-" .. target .. " 2>/dev/null || pkexec /usr/bin/tlp " ..
      ((target == "cheia") and "fullcharge" or "start")
  })
end

function update()
  noctalia.setUpdateInterval(2000)
  render()
end
