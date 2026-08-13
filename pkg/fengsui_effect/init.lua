local extension = Package:new("fengsui_effect", Package.SpecialPack)
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode", "fengsui_heg__mode" }

local effectRoot = "packages/fengsui/pkg/fengsui_effect/"
local oldEffectRoot = "packages/hegemony/pkg/hegemony_effect/"

local function redirect(path)
  if type(path) ~= "string" then return path end
  local prefix = path:startsWith("./") and "./" or ""
  local plain = prefix == "./" and path:sub(3) or path
  if plain:startsWith(oldEffectRoot) then
    return prefix .. effectRoot .. plain:sub(#oldEffectRoot + 1)
  end
  return path
end

if Room and not Room._fengsuiEffectRedirected then
  local originalLightBox = Room.doSuperLightBox
  Room.doSuperLightBox = function(self, path, ...)
    return originalLightBox(self, redirect(path), ...)
  end
  local originalPlaySound = Room.broadcastPlaySound
  Room.broadcastPlaySound = function(self, path, ...)
    return originalPlaySound(self, redirect(path), ...)
  end
  Room._fengsuiEffectRedirected = true
end

local function fileContains(path, needle)
  local file = io.open(path, "rb")
  if not file then return false end
  local content = file:read("*a")
  file:close()
  return content:find(needle, 1, true) ~= nil
end

local H = require "packages.hegemony.util"
local utilPath = "packages/hegemony/util.lua"
if not fileContains(utilPath, "hegemony_effect/qml/BuildCountry.qml") then
  local original = H.AskForBuildCountry
  H.AskForBuildCountry = function(player, generalName, isActive)
    if player.general == generalName and H.kingdomMapper[generalName] then
      local room = player.room
      room:broadcastPlaySound("./" .. effectRoot .. "audio/BGM/buildcountry")
      room:doSuperLightBox(effectRoot .. "qml/BuildCountry.qml")
      room:delay(1000)
    end
    return original(player, generalName, isActive)
  end
end

if not fileContains(utilPath, "hegemony_effect/qml/aozhan.qml") then
  local original = H.enterBattleRoyalMode
  H.enterBattleRoyalMode = function(room)
    room:broadcastPlaySound("./" .. effectRoot .. "audio/BGM/aozhan_start")
    room:doSuperLightBox(effectRoot .. "qml/aozhan.qml")
    room:delay(2400)
    return original(room)
  end
end

Fk._fengsuiNativeHegemonyRevealEffects = fileContains(
  "packages/hegemony/pkg/gamemodes/skills/hegemony_rule.lua",
  "hegemony_effect/qml/Vanguard.qml"
)
extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_effect/skills")

Fk:loadTranslationTable{
  ["fengsui_effect"] = "烽燧燎原-特效",
}

return extension
