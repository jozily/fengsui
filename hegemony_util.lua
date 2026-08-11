-- Keep Fengsui usable with both the newer hegemony package and the
-- ol_hegemony implementation bundled by older FreeKill 0.5.20 builds.
local ok, modern = pcall(require, "packages.hegemony.util")
if ok then
  return modern
end

local legacy = require "packages.ol_hegemony.util"
local compat = setmetatable({}, { __index = legacy })

-- New hegemony derives the room from the player; ol_hegemony expects it.
function compat.addHegMark(player, mark_name, number)
  return legacy.addHegMark(player.room, player, mark_name, number)
end

-- New hegemony accepts room as its first argument; ol_hegemony does not.
function compat.transformGeneral(room, player, is_main, is_hidden, number)
  return legacy.transformGeneral(player, is_main, is_hidden, number)
end

-- This operation was renamed when hegemony was split from ol_hegemony.
function compat.swapDeputy(room, player, target)
  return legacy.SwapTwoPlayersDeputy(room, player, target)
end

return compat
