--!nonstrict
-- Detail panel: shows the full battery status with a button to toggle the
-- charge mode. Open with: noctalia msg panel-toggle kauadev/battery-mode:panel

local state = noctalia.state.get("battery") or {}
local mode = state.mode or "Long_Life"
local capacity = state.capacity or 0
local status = state.status or "?"

local function render()
  local modeLabel = (mode == "Standard")
    and noctalia.tr("mode.standard")
    or noctalia.tr("mode.longlife")
  local toggleLabel = (mode == "Standard")
    and noctalia.tr("action.enableLongLife")
    or noctalia.tr("action.enableStandard")

  panel.render(ui.column({ flexGrow = 1, gap = 16 }, {
    ui.row({ align = "center", justify = "space_between", gap = 8 }, {
      ui.label({ text = noctalia.tr("title"), fontSize = 16, fontWeight = "bold", flexGrow = 1 }),
      ui.button({ glyph = "refresh", tooltip = noctalia.tr("action.refresh"), onClick = "onRefresh" }),
      ui.button({ glyph = "close", onClick = "onClose" }),
    }),
    ui.column({ flexGrow = 1, gap = 12 }, {
      ui.row({ align = "center", gap = 12 }, {
        ui.box({
          width = 48, height = 48, radius = 12,
          fill = (mode == "Standard") and "tertiary/0.25" or "primary/0.20",
        }, {
          ui.glyph({
            name = (mode == "Standard") and "bolt" or "leaf",
            size = 24,
            color = (mode == "Standard") and "tertiary" or "primary",
          }),
        }),
        ui.column({ flexGrow = 1, gap = 2 }, {
          ui.label({ text = modeLabel, fontWeight = "bold" }),
          ui.label({ text = capacity .. "% • " .. status, color = "on_surface_variant", fontSize = 12 }),
        }),
      }),
      ui.label({
        text = (mode == "Standard")
          and noctalia.tr("description.standard")
          or noctalia.tr("description.longlife"),
        color = "on_surface_variant", fontSize = 12, wrap = true,
      }),
    }),
    ui.row({ gap = 8 }, {
      ui.button({
        text = toggleLabel,
        variant = (mode == "Standard") and "primary" or "primary",
        flexGrow = 1,
        onClick = "onToggle",
      }),
    }),
  }))
end

function onToggle()
  local target = (mode == "Standard") and "poupar" or "cheia"
  Quickshell.execDetached({
    "fish", "-c",
    "bat-" .. target .. " 2>/dev/null || pkexec /usr/bin/tlp " ..
      ((target == "cheia") and "fullcharge" or "start")
  })
end

function onRefresh()
  local s = noctalia.state.get("battery") or state
  if s ~= nil then
    mode = s.mode or mode
    capacity = s.capacity or capacity
    status = s.status or status
  end
  render()
end

function onClose()
  panel.close()
end

noctalia.state.watch("battery", function(value)
  if value ~= nil then
    state = value
    mode = state.mode or mode
    capacity = state.capacity or capacity
    status = state.status or status
    render()
  end
end)

function onOpen(_context)
  render()
end
