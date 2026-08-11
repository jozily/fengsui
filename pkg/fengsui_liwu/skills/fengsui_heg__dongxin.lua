local dongxin = fk.CreateSkill{
  name = "fengsui_heg__dongxin",
}

local function discardLimit(damage, cardNum)
  return math.min(damage or 1, cardNum)
end

dongxin:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local other = data.from == player and data.to or (data.to == player and data.from or nil)
    return player:hasSkill(dongxin.name) and other and other ~= player and other:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local other = data.from == player and data.to or data.from
    local card = Fk:cloneCard("reveal_intention")
    card.skillName = dongxin.name
    if player:canUseTo(card, other) then room:useVirtualCard("reveal_intention", nil, player, other, dongxin.name, true) end
    if player:isAlive() then player:drawCards(1, dongxin.name) end
    if other:isAlive() then other:drawCards(1, dongxin.name) end
    if player.dead or #player:getCardIds("he") == 0 then return end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = discardLimit(data.damage, #player:getCardIds("he")),
      pattern = ".",
      skill_name = dongxin.name,
      prompt = "#fengsui_heg__dongxin-discard",
      cancelable = true,
      include_equip = true,
    })
    if #cards == 0 then return end
    local slashes = table.filter(cards, function(id) return Fk:getCardById(id).trueName == "slash" end)
    room:recastCard(cards, player, dongxin.name)
    for _, id in ipairs(slashes) do
      if player.dead then break end
      if room:getCardArea(id) == Card.DiscardPile then
        local use = room:askToUseRealCard(player, {
          pattern = tostring(Exppattern{ id = { id } }),
          skill_name = dongxin.name,
          prompt = "#fengsui_heg__dongxin-use",
          cancelable = true,
          skip = true,
          expand_pile = { id },
          extra_data = { bypass_times = true },
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        end
      end
    end
  end,
})

dongxin:addTest(function(room, me)
  lu.assertEquals(discardLimit(2, 5), 2)
  lu.assertEquals(discardLimit(3, 1), 1)
end)

return dongxin
