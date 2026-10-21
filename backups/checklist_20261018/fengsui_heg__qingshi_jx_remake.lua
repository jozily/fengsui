local s = fk.CreateSkill { name = "fengsui_heg__qingshi_jx" }
s:addEffect(fk.TargetConfirming, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(s.name) and data.from and data.from ~= player and player:getMark(s.name .. "-round") == 0 and
      data.card and data.card.color == Card.Black and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local eligible = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Black
    end)
    if #eligible == 0 then return false end
    local cards = player.room:askToCards(player, {
      min_num = 1, max_num = 1, include_equip = false,
      pattern = tostring(Exppattern { id = eligible }), skill_name = s.name, cancelable = true,
    })
    if #cards == 0 then return false end
    event:setCostData(self, cards)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(event:getCostData(self)[1])
    room:setPlayerMark(player, s.name .. "-round", 1)
    data:cancelTarget(player)
    room:throwCard(card:getEffectiveId(), s.name, player, player)
    if data.card and data.card:getEffectiveId() > 0 and room:getCardArea(data.card:getEffectiveId()) ~= Card.Void then
      room:obtainCard(player, data.card, true, fk.ReasonPrey, player, s.name)
    end
  end,
})
return s
