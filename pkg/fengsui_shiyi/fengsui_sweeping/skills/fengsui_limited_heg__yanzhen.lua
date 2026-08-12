local H = require "packages.hegemony.util"
local yanzhen = fk.CreateSkill { name = "fengsui_limited_heg__yanzhen" }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__yanzhen"] = "孤胆",
  [":fengsui_limited_heg__yanzhen"] = "当你明置此武将牌后或每轮首次受到伤害后，你可以令当前回合角色执行一个军令。若其不执行，你获得一张【杀】，此【杀】无距离限制且不计入次数；若其执行，你暗置此武将牌。",
}

local function triggerable(player)
  return player.room.current and player.room.current:isAlive()
end

local spec = {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yanzhen.name) or not triggerable(player) then return false end
    if event == fk.GeneralRevealed then
      return data.m == "fengsui_limited_heg__zhanjiangmd" or data.d == "fengsui_limited_heg__zhanjiangmd"
    end
    return player:usedSkillTimes(yanzhen.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = yanzhen.name })
  end,
  on_use = function(self, event, target, player, data)
    local room, current = player.room, player.room.current
    if H.askToCommand(player, { tos = { current }, skill_name = yanzhen.name }) then
      H.hideBySkillName(player, yanzhen.name, true)
    else
      local ids = room:getCardsFromPileByRule("slash", 1, "allPiles")
      if #ids > 0 then
        room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonPrey, yanzhen.name, nil, true, player)
        room:setCardMark(Fk:getCardById(ids[1]), "@@fengsui_limited_heg__yanzhen-inhand", 1)
      end
    end
  end,
}
yanzhen:addEffect(fk.GeneralRevealed, spec)
yanzhen:addEffect(fk.Damaged, spec)
yanzhen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card) return card and card:getMark("@@fengsui_limited_heg__yanzhen-inhand") > 0 end,
  bypass_distances = function(self, player, skill, card) return card and card:getMark("@@fengsui_limited_heg__yanzhen-inhand") > 0 end,
})

return yanzhen
