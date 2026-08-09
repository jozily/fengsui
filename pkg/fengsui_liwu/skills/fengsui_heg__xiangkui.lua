local s = fk.CreateSkill { name = "fengsui_heg__xiangkui" }

s:addEffect(fk.EventPhaseStart, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target and target ~= player and target.phase == Player.Play and player:hasSkill(s.name) and
      not player:isKongcheng() and target:getMark(s.name .. "-phase") == 0
  end,
  on_cost = function(self, event, target, player, data)
    if not player.room:askToSkillInvoke(target, { skill_name = s.name, prompt = "#fengsui_heg__xiangkui-invoke::" .. player.id }) then
      return false
    end
    local choice = player.room:askToChoice(target, {
      choices = { "basic", "trick", "equip" }, skill_name = s.name,
    })
    event:setCostData(self, choice)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, s.name .. "-phase", 1)
    local cards = room:askToCards(player, {
      min_num = 1, max_num = player:getHandcardNum(), include_equip = false,
      skill_name = s.name, prompt = "#fengsui_heg__xiangkui-give::" .. target.id,
      cancelable = true,
    })
    if #cards == 0 then return end
    local types, matched = {}, false
    for _, id in ipairs(cards) do
      local cardType = Fk:getCardById(id):getTypeString()
      table.insertIfNeed(types, cardType)
      if cardType == event:getCostData(self) then matched = true end
    end
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, s.name, nil, true, player)
    if player:isAlive() then player:drawCards(#types + (matched and 2 or 0), s.name) end
  end,
})

return s
