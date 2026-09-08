require("copy_on_select").load()

-- Match Ghostty's palette, and shrink the stock alert -- it defaults to 27pt
-- text in a 27pt-radius box dead centre of the screen. Must come before the
-- reload alert below, which would otherwise render unstyled.
hs.alert.defaultStyle.fillColor = { hex = "#151C23", alpha = 0.95 }
hs.alert.defaultStyle.strokeColor = { hex = "#FFA900" } -- the app icon's amber
hs.alert.defaultStyle.strokeWidth = 1
hs.alert.defaultStyle.radius = 8
hs.alert.defaultStyle.textColor = { hex = "#C2C2C2" }
hs.alert.defaultStyle.textSize = 14
-- 0 is screen centre; the top edge tucks the alert under the notch.
hs.alert.defaultStyle.atScreenEdge = 0

-- hs.reload() tears down the Lua state, so anything after it in a callback
-- never runs -- an alert there is silently dropped. Leave a flag behind
-- instead and let the fresh state announce itself, which also keeps the alert
-- to manual reloads rather than every launch.
local manualReloadKey = "manualReload"

if hs.settings.get(manualReloadKey) then
	hs.settings.clear(manualReloadKey)
	hs.alert.show("Hammerspoon config reloaded")
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	hs.settings.set(manualReloadKey, true)
	hs.reload()
end)
