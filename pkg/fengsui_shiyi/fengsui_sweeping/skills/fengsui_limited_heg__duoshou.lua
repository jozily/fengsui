local H = require "packages.hegemony.util"
local duoshou = fk.CreateSkill { name = "fengsui_limited_heg__duoshou", tags = { Skill.Limited } }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__duoshou"] = "夺首",
  [":fengsui_limited_heg__duoshou"] = "限定技，当一名与你势力不同的角色进入濒死状态时，你可以明置此武将牌，将此伤害来源改为你，然后此次击杀奖励改为2X张牌（X为游戏轮数）。",
}

duoshou:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(duoshou.name, true) and player:usedSkillTimes(duoshou.name, Player.HistoryGame) == 0 and
      target ~= player and not H.compareKingdomWith(player, target) and data.damage
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = duoshou.name })
  end,
  on_use = function(self, event, target, player, data)
    local place = H.inGeneralSkills(player, duoshou.name)
    if place then player:revealGeneral(place == "d") end
    data.damage.from = player
    player.room:setPlayerMark(target, "fengsui_limited_heg__duoshou_reward", 2 * (player.room:getBanner("RoundCount") or 1))
  end,
})

return duoshou
