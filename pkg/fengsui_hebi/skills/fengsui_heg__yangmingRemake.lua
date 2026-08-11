local s = fk.CreateSkill { name = "fengsui_heg__yangmingRemake" }

local function kingdomCount(room)
  local kingdoms = {}
  for _, p in ipairs(room.alive_players) do
    if p.kingdom ~= "unknown" and p.kingdom ~= "fengsui_neutral" and p.kingdom ~= "fengsui_neutralall" then
      table.insertIfNeed(kingdoms, p.kingdom)
    end
  end
  return #kingdoms
end

s:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and data.card
  end,
  on_cost = function()
    return true
  end,
  on_use = function(self, event, target, player, data)
    local types = player:getTableMark(s.name .. "-turn")
    table.insertIfNeed(types, data.card:getTypeString())
    player.room:setPlayerMark(player, s.name .. "-turn", types)
  end,
})

s:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(s.name) and #player:getTableMark(s.name .. "-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = s.name })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = #player:getTableMark(s.name .. "-turn")
    player:drawCards(x, s.name)
    if player.dead or x < kingdomCount(room) or player:isKongcheng() then return end
    room:showCards(player:getCardIds("h"), player, player)
    local chosenKingdoms = {}
    for _ = 1, x do
      if player.dead or player:isKongcheng() then break end
      local targets = table.filter(room:getOtherPlayers(player), function(p)
        return p:isAlive() and p.kingdom ~= "unknown" and p.kingdom ~= "fengsui_neutral" and p.kingdom ~= "fengsui_neutralall" and
          not table.contains(chosenKingdoms, p.kingdom)
      end)
      if #targets == 0 then break end
      local tos, cards = room:askToChooseCardsAndPlayers(player, {
        min_num = 1, max_num = 1, min_card_num = 1, max_card_num = 1,
        targets = targets, pattern = ".|.|.|hand", skill_name = s.name,
        prompt = "#fengsui_heg__yangmingRemake-give", cancelable = false,
      })
      if #tos == 0 or #cards == 0 then break end
      table.insertIfNeed(chosenKingdoms, tos[1].kingdom)
      room:moveCardTo(cards, Card.PlayerHand, tos[1], fk.ReasonGive, s.name, nil, true, player)
    end
  end,
})

return s
