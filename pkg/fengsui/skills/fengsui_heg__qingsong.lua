local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local qingsong = fk.CreateSkill{
  name = "fengsui_heg__qingsong",
}

qingsong:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingsong.name) and
      H.allGeneralsRevealed(player) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local candidates = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).type ~= data.card.type
    end)
    local cards = U.chooseCardsFromList(player.room, player, candidates, 1, 1,
      "#fengsui_heg__qingsong-give", qingsong.name, true)
    if #cards == 0 then return false end
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      skill_name = qingsong.name,
      prompt = "#fengsui_heg__qingsong-to",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {card = cards[1], to = tos[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    U.hideSkillGeneral(player, qingsong.name)
    room:moveCardTo(cost.card, Card.PlayerHand, cost.to, fk.ReasonGive,
      qingsong.name, nil, true, player)
    if not H.compareKingdomWith(player, cost.to) then
      room:addTableMark(player, "fengsui_heg__qingsong_use-turn", cost.card)
    end
  end,
})

qingsong:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return #player:getTableMark("fengsui_heg__qingsong_use-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getTableMark("fengsui_heg__qingsong_use-turn")
    room:setPlayerMark(player, "fengsui_heg__qingsong_use-turn", 0)
    for _, id in ipairs(cards) do
      if player:isAlive() and room:getCardArea(id) == Card.PlayerHand then
        room:askToUseRealCard(player, {
          pattern = {id},
          expand_pile = {id},
          skill_name = qingsong.name,
          prompt = "#fengsui_heg__qingsong-use",
          cancelable = false,
        })
      end
    end
  end,
})

return qingsong
