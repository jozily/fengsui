local cangjuan = fk.CreateSkill{
  name = "fengsui_heg__cangjuan",
}

local zhao_pile = "@[zhaoshu]"

local function findCard(room, name, areas)
  for _, p in ipairs(room.players) do
    for _, id in ipairs(p:getCardIds("hej")) do
      if Fk:getCardById(id).name == name and table.contains(areas, room:getCardArea(id)) then return id end
    end
    for _, id in ipairs(p:getPile(zhao_pile)) do
      if Fk:getCardById(id).name == name and table.contains(areas, room:getCardArea(id)) then return id end
    end
  end
  for _, id in ipairs(room.draw_pile) do
    if Fk:getCardById(id).name == name and table.contains(areas, room:getCardArea(id)) then return id end
  end
end

local function findImperialOrder(room)
  for _, p in ipairs(room.players) do
    for _, id in ipairs(p:getCardIds("h")) do
      if Fk:getCardById(id).name == "imperial_order" then return id, p end
    end
  end
  for _, id in ipairs(room.draw_pile) do
    if Fk:getCardById(id).name == "imperial_order" then return id end
  end
end

local function useRealCard(room, player, ids, prompt, countTimes)
  if not ids then return end
  if type(ids) ~= "table" then ids = { ids } end
  if #ids == 0 then return end
  local use = room:askToUseRealCard(player, {
    pattern = tostring(Exppattern{ id = ids }),
    skill_name = cangjuan.name,
    prompt = prompt,
    cancelable = false,
    skip = true,
    expand_pile = ids,
    extra_data = {
      bypass_times = countTimes ~= true,
      bypass_distances = true,
      not_passive = false,
    },
  })
  if use then
    local countsTimes = countTimes == true or table.contains({ "slash", "analeptic" }, use.card.trueName)
    if countsTimes then
      use.extraUse = nil
      use.extra_data = use.extra_data or {}
      use.extra_data.bypass_times = false
    else
      use.extraUse = true
    end
    room:useCard(use)
  end
  return use
end

cangjuan:addEffect(fk.GeneralRevealed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cangjuan.name) and
      player:getMark("fengsui_heg__cangjuan_revealed") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__cangjuan_revealed", 1)

    if not room:getTag("ImperialOrderHasRemoved") then
      local imperial, owner = findImperialOrder(room)
      if imperial then
        useRealCard(room, player, imperial, "#fengsui_heg__cangjuan-imperial")
        if owner and owner:isAlive() then owner:drawCards(1, cangjuan.name) end
      end
    end
    if player.dead then return end

    local zhaoshu_on_field = findCard(room, "heg_zhaoshu", {
      Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge, Card.PlayerSpecial,
    })
    if zhaoshu_on_field then return end
    local zhaoshu = room:prepareDeriveCards({ { "heg_zhaoshu", Card.Club, 3 } }, "chiling_zhaoshu")[1]
    if not zhaoshu then return end
    room:moveCardTo(zhaoshu, Card.PlayerHand, player, fk.ReasonPrey, cangjuan.name, nil, true, player)
    if not player.dead and room:getCardOwner(zhaoshu) == player then
      useRealCard(room, player, zhaoshu, "#fengsui_heg__cangjuan-zhaoshu")
    end
  end,
})

local function responsePattern()
  return type(Fk.currentResponsePattern) == "string" and Fk.currentResponsePattern ~= "" and
    Fk.currentResponsePattern or nil
end

local function availableZhaos(player, pattern)
  return table.filter(player:getPile(zhao_pile), function(id)
    local card = Fk:getCardById(id)
    return card and card.name ~= "heg_zhaoshu" and (not pattern or card:matchPattern(pattern))
  end)
end

cangjuan:addEffect("viewas", {
  pattern = ".",
  prompt = function()
    return responsePattern() and "#fengsui_heg__cangjuan-response" or "#fengsui_heg__cangjuan"
  end,
  expand_pile = zhao_pile,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 or player:getPileNameOfId(to_select) ~= zhao_pile then return false end
    local card = Fk:getCardById(to_select)
    local pattern = responsePattern()
    return card and card.name ~= "heg_zhaoshu" and (not pattern or card:matchPattern(pattern))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Fk:getCardById(cards[1]).name)
    card:addSubcard(cards[1])
    card.skillName = cangjuan.name
    return card
  end,
  after_use = function(self, player, use)
    local card = use.card
    if player.dead or not card then return end
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).suit ~= card.suit
    end)
    if #cards == 0 then return end
    local chosen = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = cangjuan.name,
      prompt = "#fengsui_heg__cangjuan-put:::" .. Fk:translate(Card.getSuitString(card, true)),
      cancelable = false,
    })
    if #chosen > 0 then player:addToPile(zhao_pile, chosen, true, cangjuan.name) end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(cangjuan.name, Player.HistoryTurn) == 0 and #availableZhaos(player) > 0
  end,
  enabled_at_response = function(self, player)
    local pattern = responsePattern()
    return player:usedSkillTimes(cangjuan.name, Player.HistoryTurn) == 0 and
      pattern and #availableZhaos(player, pattern) > 0
  end,
})

cangjuan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, cangjuan.name) and
      not table.contains({ "slash", "analeptic" }, card.trueName)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, cangjuan.name)
  end,
})

return cangjuan
