local U = require "packages.fengsui.pkg.fengsui_shiyi.fengsui_sweeping.sweeping_util"
local meimo = fk.CreateSkill { name = "fengsui_limited_heg__meimo", tags = { Skill.Compulsory } }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__meimo"] = "魅魔",
  [":fengsui_limited_heg__meimo"] = "锁定技，你于回合内使用的前X张牌不计入次数，前Y张牌无距离限制；出牌阶段开始时，若X=Y，你摸X张牌（X为同势力角色数，Y为场上势力数）。",
}

meimo:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(meimo.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "fengsui_limited_heg__meimo_cards-turn")
  end,
})

meimo:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill(meimo.name) and player:getMark("fengsui_limited_heg__meimo_cards-turn") < U.sameKingdomCount(player)
  end,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(meimo.name) and player:getMark("fengsui_limited_heg__meimo_cards-turn") < U.kingdomCount(player.room)
  end,
})

meimo:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(meimo.name) and
      U.sameKingdomCount(player) == U.kingdomCount(player.room)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(U.sameKingdomCount(player), meimo.name)
  end,
})

return meimo
