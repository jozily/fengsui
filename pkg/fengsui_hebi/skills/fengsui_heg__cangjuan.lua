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

local function useRealCard(room, player, ids, prompt)
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
    extra_data = { bypass_times = true, bypass_distances = true, not_passive = false },
  })
  if use then
    use.extraUse = true
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

cangjuan:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#fengsui_heg__cangjuan",
  can_use = function(self, player)
    return player:usedSkillTimes(cangjuan.name, Player.HistoryTurn) == 0 and
      table.find(player:getPile(zhao_pile), function(id)
        return Fk:getCardById(id).name ~= "heg_zhaoshu"
      end) ~= nil
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local zhaos = table.filter(player:getPile(zhao_pile), function(id)
      return Fk:getCardById(id).name ~= "heg_zhaoshu"
    end)
    local use = useRealCard(room, player, zhaos, "#fengsui_heg__cangjuan-use")
    if not use or player.dead then return end
    local suit = use.card.suit
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).suit ~= suit
    end)
    if #cards == 0 then return end
    local chosen = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = cangjuan.name,
      prompt = "#fengsui_heg__cangjuan-put:::" .. Fk:translate(Card.getSuitString(use.card, true)),
      cancelable = false,
    })
    if #chosen > 0 then player:addToPile(zhao_pile, chosen, true, cangjuan.name) end
  end,
})

return cangjuan
