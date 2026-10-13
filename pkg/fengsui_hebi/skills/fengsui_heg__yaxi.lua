local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local H = require "packages.fengsui.hegemony_util"
local yaxi = fk.CreateSkill { name = "fengsui_heg__yaxi" }

yaxi:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    if not target or target == player or not player:hasShownSkill(yaxi.name) or
      player:getMark(yaxi.name .. "-round") > 0 or
      not data or not data.skill or data.skill.is_delay_effect or
      H.getGeneralsRevealedNum(target) ~= 2 then return false end
    local name = data.skill:getSkeleton().name
    return U.getSkillPlace(target, name) ~= nil and
      target:usedSkillTimes(name, Player.HistoryRound) > 1
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    room:setPlayerMark(player, yaxi.name .. "-round", 1)
    local place = U.getSkillPlace(target, data.skill:getSkeleton().name)
    if place == nil then return end
    target:drawCards(1, yaxi.name)
    if target.dead then return end
    U.prohibitReveal(target, place, yaxi.name, "turn")
    target:hideGeneral(place)
  end,
})

yaxi:addEffect(fk.RoundStart, {
  global = true,
  can_refresh = function(self, _, target)
    return target and target:getMark(yaxi.name .. "-round") > 0
  end,
  on_refresh = function(self, _, target)
    target.room:setPlayerMark(target, yaxi.name .. "-round", 0)
  end,
})

return yaxi
