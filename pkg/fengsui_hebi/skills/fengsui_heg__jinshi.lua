local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local jinshi = fk.CreateSkill { name = "fengsui_heg__jinshi", tags = { Skill.Compulsory } }
local readyMark = "fengsui_heg__jinshi_ready"

local function otherGeneralShown(player, data)
  local place = U.getSkillPlace(player, jinshi.name)
  return place ~= nil and data and ((place == false and data.d) or (place == true and data.m))
end

local function punish(player)
  local place = U.getSkillPlace(player, jinshi.name)
  if place == nil then return end
  local room = player.room
  player:hideGeneral(place)
  room:loseHp(player, 1, jinshi.name)
  room:setPlayerMark(player, readyMark, 1)
end

jinshi:addEffect(fk.GeneralRevealed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(jinshi.name) and otherGeneralShown(player, data)
  end,
  on_use = function(self, _, _, player)
    punish(player)
  end,
})

jinshi:addEffect(H.GeneralTransformed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local place = U.getSkillPlace(player, jinshi.name)
    return target == player and player:hasShownSkill(jinshi.name) and place ~= nil and data and
      data.isMain == place
  end,
  on_use = function(self, _, _, player)
    punish(player)
  end,
})

jinshi:addEffect(H.GeneralRemoved, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local place = U.getSkillPlace(player, jinshi.name)
    return target == player and player:hasShownSkill(jinshi.name) and place ~= nil and data and
      data.isDeputy ~= place
  end,
  on_use = function(self, _, _, player)
    punish(player)
  end,
})

jinshi:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player, data)
    local place = U.getSkillPlace(player, jinshi.name)
    return target == player and player:hasShownSkill(jinshi.name) and player:getMark(readyMark) > 0 and
      data and ((place == false and data.m) or (place == true and data.d))
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    room:setPlayerMark(player, readyMark, 0)
    local n = player:getMaxCards() - player:getHandcardNum()
    if n > 0 then room:drawCards(player, n, jinshi.name) end
  end,
})

return jinshi
