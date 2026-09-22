-- Minimal Hyprland config for the SDDM Wayland greeter.
-- SDDM starts the greeter itself after the compositor is ready.
--
-- The layout is the one chosen during setup. localectl writes it to
-- /etc/vconsole.conf as XKBLAYOUT. The desktop session reads that same file,
-- then puts a Latin layout first so keybindings keep working. The greeter has
-- no keybindings, and the password is typed in the layout from setup, so that
-- layout is the one that is active here.

local function read_vconsole()
  local values = {}
  local file = io.open("/etc/vconsole.conf", "r")
  if not file then
    return values
  end

  for line in file:lines() do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key and value then
      value = value:gsub("%s+#.*$", "")
      value = value:gsub('^"(.*)"$', "%1")
      value = value:gsub("^'(.*)'$", "%1")
      values[key] = value
    end
  end

  file:close()
  return values
end

local vconsole = read_vconsole()

hl.config({
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
  },

  animations = {
    enabled = false,
  },

  input = {
    kb_layout = vconsole.XKBLAYOUT or "us",
    kb_variant = vconsole.XKBVARIANT or "",
    kb_model = "",
    kb_options = "compose:caps,shift:both_capslock_cancel",
    numlock_by_default = true,
  },
})
