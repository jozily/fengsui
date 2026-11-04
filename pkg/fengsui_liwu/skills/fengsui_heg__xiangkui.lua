local s = fk.CreateSkill { name = "fengsui_heg__xiangkui" }

local function differentTypeCards(player, cardType)
  return table.filter(player:getCardIds("he"), function(id)
    return Fk:getCardById(id):getTypeString() ~= cardType
  end)
end

s:addEffect(fk.TurnStart, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target and target ~= player and player:hasShownSkill(s.name) and not player:isNude() and not target:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local shown = room:askToCards(target, {
      min_num = 1, max_num = 1, include_equip = true, skill_name = s.name,
      prompt = "#fengsui_heg__xiangkui-show", cancelable = true,
    })
    if #shown == 0 then return false end
    room:showCards(shown, target, target)
    event:setCostData(self, { card = shown[1] })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local shown = Fk:getCardById(event:getCostData(self).card)
    if not shown then return end
    if not room:askToSkillInvoke(player, { skill_name = s.name, prompt = "#fengsui_heg__xiangkui-invoke::" .. target.id }) then return end
    local available = differentTypeCards(player, shown:getTypeString())
    if #available == 0 then return end
    local cards = room:askToCards(player, {
      min_num = 0, max_num = #available,
      pattern = tostring(Exppattern{ id = available }), include_equip = true,
      skill_name = s.name, prompt = "#fengsui_heg__xiangkui-give::" .. target.id,
      cancelable = true,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, s.name, nil, true, player)
      room:setPlayerMark(player, "fengsui_heg__yangming-gave-turn", 1)
    end
  end,
})

return s
