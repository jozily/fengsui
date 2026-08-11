local H = require "packages.fengsui.hegemony_util"

local kuizhen = fk.CreateSkill{
  name = "fengsui_heg__kuizhen",
}

kuizhen:addEffect("active", {
  anim_type = "offensive",
  prompt = "溃阵：弃置一张黑色【杀】，令一名势力不同的角色对你使用【决斗】",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kuizhen.name, Player.HistoryPhase) == 0 and
      table.find(player:getCardIds("he"), function(id)
        local card = Fk:getCardById(id)
        return card.trueName == "slash" and card.color == Card.Black
      end) ~= nil
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return table.contains(player:getCardIds("he"), to_select) and
      card.trueName == "slash" and card.color == Card.Black
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not H.compareKingdomWith(to_select, player) and
      to_select:canUseTo(Fk:cloneCard("duel"), player, {bypass_times = true})
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]

    room:throwCard(effect.cards, kuizhen.name, player, player)

    local use = room:useVirtualCard("duel", nil, target, player, kuizhen.name, true)
    if use and use.damageDealt and use.damageDealt[player] and target:isAlive() then
      local handcards = target:getCardIds("h")
      if #handcards > 0 then room:showCards(handcards, target) end
      local slashes = table.filter(target:getCardIds("h"), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #slashes > 0 and player:isAlive() then
        room:obtainCard(player, slashes, true, fk.ReasonPrey, target, kuizhen.name)
      else
        room:loseHp(target, 1, kuizhen.name)
      end
    end
  end,
})

return kuizhen
