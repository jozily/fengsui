local fudao = fk.CreateSkill{
  name = "fengsui_heg__fudao",
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

local function getFudaoUse(player)
  local event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
  if not event then return end
  local use = event.data
  local extra = use.extra_data or {}
  if extra.fengsui_heg__fudao_from == player.id then return use end
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

fudao:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fudao.name) and
      player:usedSkillTimes(fudao.name, Player.HistoryGame) == 0 and not player:isKongcheng() and
      data.card.is_damage_card and not data.card.multiple_targets and data:isOnlyTarget(data.to)
  end,
  on_cost = function(self, event, target, player, data)
    local names = getUsedDamageNames(player)
    table.insertIfNeed(names, data.card.name)
    local x = #names
    if player.room:askToSkillInvoke(player, {
      skill_name = fudao.name,
      prompt = "#fengsui_heg__fudao-invoke::" .. data.to.id .. ":" .. x,
    }) then
      event:setCostData(self, {x = x})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(player:getCardIds("h"), fudao.name, player, player)
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__fudao_from = player.id
    data.extra_data.fengsui_heg__fudao_to = data.to.id
    data.extra_data.fengsui_heg__fudao_x = event:getCostData(self).x
  end,
})

fudao:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local use = getFudaoUse(player)
    return target == player and use and data.to.id == use.extra_data.fengsui_heg__fudao_to and
      data.card == use.card
  end,
  on_use = function(self, event, target, player, data)
    local use = getFudaoUse(player)
    data:changeDamage(use.extra_data.fengsui_heg__fudao_x)
  end,
})

fudao:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    local extra = data.extra_data or {}
    if extra.fengsui_heg__fudao_from ~= player.id or not extra.fengsui_heg__fudao_to then return false end
    local to = player.room:getPlayerById(extra.fengsui_heg__fudao_to)
    return target == player and player:isAlive() and to and to:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.extra_data.fengsui_heg__fudao_to)
    for _, id in ipairs(getDiscardDamageCards(room)) do
      if player.dead or to.dead then break end
      if room:getCardArea(id) == Card.DiscardPile then
        room:useCard{
          from = to,
          tos = {player},
          card = Fk:getCardById(id),
          extraUse = true,
        }
      end
    end
  end,
})

return fudao
