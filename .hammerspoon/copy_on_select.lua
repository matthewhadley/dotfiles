local application = require("hs.application")
local eventtap = require("hs.eventtap")
local eventTypes = eventtap.event.types
local timer = require("hs.timer")

local M = {}

-- Apps that copy on select by themselves, and are harmed by a second attempt.
-- Ghostty does it natively via `copy-on-select`, and its `super+c` binding is
-- performable: with `mouse=a` Neovim owns the drag, so Ghostty holds no
-- selection, the copy is a no-op, and the key falls through to the pty with
-- the Command modifier dropped. Neovim then sees a bare `c` -- in Visual mode
-- that is `change`, which deletes the selection.
local excludedBundleIDs = {
	["com.mitchellh.ghostty"] = true,
}

local function isExcluded()
	local app = application.frontmostApplication()

	return app ~= nil and excludedBundleIDs[app:bundleID()] == true
end

local dragCount = 0
local clickStack = {}

local function trackClick()
	clickStack[2] = clickStack[1]
	clickStack[1] = timer.secondsSinceEpoch()

	return false
end

local function incrementDragCount()
	dragCount = dragCount + 1

	return false
end

local function wasDoubleClick()
	if not clickStack[2] then
		return false
	end

	return clickStack[1] - clickStack[2] <= eventtap.doubleClickInterval()
end

local function wasDragging()
	return dragCount > 10
end

local function handleMouseUp()
	local additionalEvents = {}

	if (wasDragging() or wasDoubleClick()) and not isExcluded() then
		additionalEvents = {
			eventtap.event.newKeyEvent({ "cmd" }, "c", true),
			eventtap.event.newKeyEvent({ "cmd" }, "c", false),
		}
	end
	dragCount = 0

	return false, additionalEvents
end

M._mouseDownEvent = eventtap.new({ eventTypes.leftMouseDown }, trackClick)
M._mouseDragEvent = eventtap.new({ eventTypes.leftMouseDragged }, incrementDragCount)
M._mouseUpEvent = eventtap.new({ eventTypes.leftMouseUp }, handleMouseUp)

M.load = function()
	M._mouseDownEvent:start()
	M._mouseDragEvent:start()
	M._mouseUpEvent:start()
end

return M
