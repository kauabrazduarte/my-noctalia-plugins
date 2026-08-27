--!nonstrict
-- Control-center quick-toggle tile: shows current mode, click toggles.

local state = noctalia.state.get("battery") or {}
local mode = state.mode or "Long_Life"

local function render()
  if mode == "Standard" then
    shortcut.setLabel("100%")
    shortcut.setIcon("bolt")
  else
    shortcut.setLabel("60%")
    shortcut.setIcon("leaf")
  end
  shortcut.setActive(true)
  shortcut.setEnabled(true)
end

noctalia.state.watch("battery", function(value)
  if value ~= nil then
    mode = value.mode or mode
    render()
  end
end)

render()

function onClick()
  local target = (mode == "Standard") and "poupar" or "cheia"
  Quickshell.execDetached({
    "fish", "-c",
    "bat-" .. target .. " 2>/dev/null || pkexec /usr/bin/tlp " ..
      ((target == "cheia") and "fullcharge" or "start")
  })
end
