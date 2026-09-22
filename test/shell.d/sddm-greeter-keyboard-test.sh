#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

require_command lua

resolved_greeter() {
  OMARCHY_VCONSOLE="${1-}" lua <<'LUA'
local vconsole = os.getenv("OMARCHY_VCONSOLE")
local real_open = io.open

io.open = function(path, mode)
  if path ~= "/etc/vconsole.conf" then
    return real_open(path, mode)
  end

  if not vconsole then
    return nil
  end

  local file = io.tmpfile()
  file:write(vconsole)
  file:seek("set")
  return file
end

hl = {
  config = function(config)
    local input = config.input
    print(("[%s] [%s] [%s] [%s]"):format(
      input.kb_layout,
      input.kb_variant,
      input.kb_options,
      tostring(input.numlock_by_default)
    ))
  end,
}

dofile(os.getenv("OMARCHY_GREETER"))
LUA
}

assert_greeter() {
  local description="$1"
  local expected="$2"
  local actual

  if (( $# > 2 )); then
    actual=$(OMARCHY_GREETER="$ROOT/default/sddm/hyprland.lua" resolved_greeter "$3")
  else
    actual=$(OMARCHY_GREETER="$ROOT/default/sddm/hyprland.lua" resolved_greeter)
  fi

  [[ $actual == "$expected" ]] ||
    fail "$description" "expected: $expected"$'\n'"actual:   $actual"
  pass "$description"
}

options="compose:caps,shift:both_capslock_cancel"

assert_greeter "missing vconsole.conf falls back to us" "[us] [] [$options] [true]"
assert_greeter "setup layout is the greeter layout" "[dk] [] [$options] [true]" 'KEYMAP=dk-latin1
XKBLAYOUT=dk
XKBMODEL=pc105
'
assert_greeter "setup variant is kept" "[de] [nodeadkeys] [$options] [true]" 'XKBLAYOUT=de
XKBVARIANT=nodeadkeys
'
assert_greeter "non-latin setup layout stays first" "[ru] [] [$options] [true]" 'XKBLAYOUT=ru
'
assert_greeter "quoted layout and trailing comment are stripped" "[fr] [] [$options] [true]" 'XKBLAYOUT="fr" # chosen at setup
'
