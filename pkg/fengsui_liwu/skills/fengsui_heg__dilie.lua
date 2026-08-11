local dilie = fk.CreateSkill{
  name = "fengsui_heg__dilie",
}

local function isCurio(card)
  return card and card.package and card.package.name == "nine_variations"
end

dilie:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(dilie.name) and table.find(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    local chosen = player.room:askToCards(player, {
      min_num = 1,
      max_num = #cards,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = dilie.name,
      prompt = "#fengsui_heg__dilie-recast",
      cancelable = true,
      include_equip = true,
    })
    if #chosen > 0 then
      event:setCostData(self, chosen)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recastCard(event:getCostData(self), player, dilie.name)
  end,
})

dilie:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dilie.name) and #player:getEquipments(Card.SubtypeWeapon) == 0 and
      table.find(player.room.discard_pile, function(id)
        return Fk:getCardById(id).sub_type == Card.SubtypeWeapon
      end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not room:askToSkillInvoke(player, { skill_name = dilie.name }) then return false end
    local weapons = table.filter(room.discard_pile, function(id)
      return Fk:getCardById(id).sub_type == Card.SubtypeWeapon
    end)
    local id = room:askToChooseCard(player, {
      target = player,
      flag = { card_data = { { "$DiscardPile", weapons } } },
      skill_name = dilie.name,
      prompt = "#fengsui_heg__dilie-weapon",
    })
    if id then
      event:setCostData(self, id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self)
    local curio = isCurio(Fk:getCardById(id))
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, dilie.name, nil, true, player)
    if curio and data.from and data.from:isAlive() and player:isAlive() then
      room:damage{ from = player, to = data.from, damage = 1, skillName = dilie.name }
    end
  end,
})

return dilie
