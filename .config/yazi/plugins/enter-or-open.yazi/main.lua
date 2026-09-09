--- Enter on a directory: record its path and quit, so the shell you launched
--- yazi from lands there (the y() wrapper in .zshrc.d/02.aliases.zsh reads it).
--- Enter on anything else: the normal `open` behaviour.
---
--- A plugin rather than a keybinding or an opener because this needs a condition
--- on the hovered entry, and the keymap has no conditionals. It also runs
--- in-process, avoiding `ya emit` -- that talks over yazi's IPC socket, which is
--- absent unless DDS is enabled and otherwise fails with ENOENT.
---
--- The path is written here rather than via yazi's own --cwd-file, because that
--- would require cd'ing into the directory first, and the cd forces a full
--- repaint of the target directory for one frame before quit lands -- a visible
--- flash. Writing the path directly means yazi never navigates and never
--- redraws.
---
--- `app:quit`, not `quit`. ya.emit hardcodes Layer::Mgr, and mgr:quit shows the
--- "There are unfinished tasks, quit anyway?" confirm whenever
--- tasks.scheduler.ongoing is non-empty -- which it always is here, because the
--- running plugin is itself an ongoing task. mgr:quit calls app:quit directly
--- only when that list is empty. Action::new parses a "layer:name" prefix, so
--- naming the app layer reaches the same endpoint without the check. Plain `q`
--- escapes the confirm only because no plugin task is in flight.
---
--- Rejected on the way here: quit --force (no such option), `close` instead of
--- quit, quitting inside ya.sync, auto-answering with close --submit, and
--- `plugin ... --sync` (flag unrecognised, the binding no-ops). A keymap sequence
--- [plugin, quit] is confirm-free but races ahead of the write below, and can't
--- branch on file-vs-directory.
---
--- `entry` runs in async context, where `cx` is not available -- reading it there
--- silently does nothing, with no error. Hence the ya.sync wrapper: state is read
--- in sync context and only the resulting path crosses back.

local hovered_dir = ya.sync(function()
	local h = cx.active.current.hovered
	if h and h.cha.is_dir then
		return tostring(h.url)
	end
	return nil
end)

return {
	entry = function()
		local dir = hovered_dir()

		-- Not a directory: hand over to the normal open path.
		if not dir then
			ya.emit("open", {})
			return
		end

		local target = os.getenv("YAZI_CD_TARGET")

		-- Launched as bare `yazi` rather than through y(), so nothing is going to
		-- read a path back. Just navigate in, which is the least surprising thing
		-- to do -- quitting would look like a crash.
		if not target then
			ya.emit("cd", { dir })
			return
		end

		local f = io.open(target, "w")
		if f then
			f:write(dir)
			f:close()
		end

		ya.emit("app:quit", {})
	end,
}
