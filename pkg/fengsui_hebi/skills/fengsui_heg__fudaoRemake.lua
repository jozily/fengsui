local fudao = fk.CreateSkill{
  name = "fengsui_heg__fudaoRemake",
  tags = { Skill.Limited },
}

local function getUsedDamageNames(player)
  local names = {}
  player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(event)
    local use = event.data
    if use.from == player and use.card.is_damage_card then
      table.insertIfNeed(names, use.card.name)
    end
  end, Player.HistoryTurn)
  return names
end

local function getDiscardDamageCards(room)
  local result, names = {}, {}
  room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(event)
    for _, move in ipairs(event.data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card.is_damage_card and room:getCardArea(info.cardId) == Card.DiscardPile and
            not names[card.name] then
            names[card.name] = true
            table.insert(result, info.cardId)
          end
        end
      end
    end
  end, Player.HistoryTurn)
  return result
end

fudao:addEffect(fk.PreDamage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fudao.name) and
      player:usedSkillTimes(fudao.name, Player.HistoryGame) == 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local x = #getUsedDamageNames(player)
    if player.room:askToSkillInvoke(player, {
      skill_name = fudao.name,
      prompt = "#fengsui_heg__fudaoRemake-invoke::" .. data.to.id .. ":" .. x,
    }) then
      event:setCostData(self, { x = x })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(player:getCardIds("h"), fudao.name, player, player)
    data:changeDamage(event:getCostData(self).x)
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__fudaoRemake = true
  end,
})

fudao:addEffect(fk.Damage, {
  is_delay_effect = true,
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).fengsui_heg__fudaoRemake and
      player:isAlive() and data.to:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(getDiscardDamageCards(room)) do
      if player.dead or data.to.dead then break end
      if room:getCardArea(id) == Card.DiscardPile then
        room:useCard{
          from = data.to,
          tos = {player},
          card = Fk:getCardById(id),
          extraUse = true,
        }
      end
    end
  end,
})

return fudao
