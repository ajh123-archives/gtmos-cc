local shell = require "gtmos_shell"
local os = require "gtmos_os"

local env = {
  ipairs = ipairs,
  next = next,
  pairs = pairs,
  pcall = pcall,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  unpack = unpack,
  print = print,
  colors = colors,
  colours = colours,
  term = term,
  shell = shell,
  coroutine = coroutine,
  string = string,
  table = table,
  math = math,
  os = os
}

return env