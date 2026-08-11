local s = fk.CreateSkill { name = "fengsui_heg__fuzhu_xs" }

s:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    if not target or not player:hasSkill(s.name) or target.kingdom ~= player.kingdom or not data.card then return false end
    local kind = data.card.skillName and data.card.skillName ~= "" and "converted" or "normal"
    return player:getMark(s.name .. "-round-" .. kind) == 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = s.name })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local converted = data.card.skillName and data.card.skillName ~= ""
    local kind = converted and "converted" or "normal"
    room:setPlayerMark(player, s.name .. "-round-" .. kind, 1)
    local cards = room:askToCards(player, {
      min_num = 1, max_num = 1, include_equip = false, skill_name = s.name, cancelable = false,
    })
    if #cards == 0 then return end
    room:moveCards({
      ids = cards, from = player, toArea = Card.DrawPile, moveReason = fk.ReasonPut,
      skillName = s.name, drawPilePosition = converted and -1 or 1, moveVisible = true,
    })
    local shown = room:getNCards(3, converted and "top" or "bottom")
    if #shown == 0 then return end
    room:showCards(shown, player, player)
    local types = {}
    for _, id in ipairs(shown) do table.insertIfNeed(types, Fk:getCardById(id):getTypeString()) end
    local choice = room:askToChoice(player, { choices = types, skill_name = s.name })
    local gain = table.filter(shown, function(id) return Fk:getCardById(id):getTypeString() == choice end)
    if #gain > 0 then room:obtainCard(player, gain, true, fk.ReasonPrey, player, s.name) end
  end,
})

return s
