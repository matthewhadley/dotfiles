-- Yazi Lua init. Loaded at startup; theming lives in theme.toml, behaviour in
-- yazi.toml, keys in keymap.toml.

-- ── Symlink target in the status bar ─────────────────────────────────────
-- https://yazi-rs.github.io/docs/tips/#symlink-in-status
--
-- Appends " -> /the/target" after the name of a hovered symlink. Verbatim from
-- the docs. Order 3300 puts it after the existing left-hand segments.
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

-- ── Owner and group in the status bar ────────────────────────────────────
-- https://yazi-rs.github.io/docs/tips/#user-group-in-status
--
-- Shows user:group for the hovered file, to the left of the permissions. The
-- target_family guard makes it a no-op off unix.
--
-- DEVIATION FROM THE DOCS: upstream colours both spans "magenta". That fights
-- the status bar we just made deliberately monochrome -- the permissions were
-- flattened to one colour for exactly this reason -- so both use #e6eaea
-- (terafox fg1), matching the permissions beside them. Swap the two fg() calls
-- back to "magenta" for the upstream look.
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end

	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("#e6eaea"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("#e6eaea"),
		" ",
	}
end, 500, Status.RIGHT)
