local s = fk.CreateSkill { name = "fengsui_heg__qingshi_jx" }
s:addEffect(fk.TargetConfirming, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and player:getMark(s.name .. "-round") == 0 and
      data.card and data.card.color == Card.Black and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1, max_num = 1, include_equip = false, skill_name = s.name, cancelable = true,
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
    if card.color == Card.Black then player:drawCards(1, s.name) end
  end,
})
return s
