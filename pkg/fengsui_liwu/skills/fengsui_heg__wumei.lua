local wumei = fk.CreateSkill{
  name = "fengsui_heg__wumei",
}

local function isCurio(card)
  return card and card.type == Card.TypeEquip and card.package and card.package.name == "nine_variations"
end

wumei:addEffect(fk.GeneralRevealed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wumei.name) and
      table.contains(data, "fengsui_heg__zhouxuan")
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseVirtualCard(player, {
      name = "tricky_heist",
      skill_name = wumei.name,
      prompt = "#fengsui_heg__wumei",
      cancelable = true,
      skip = true,
    })
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__wumei_using", 1)
    room:setPlayerMark(player, "fengsui_heg__wumei_obtained", 0)
    room:useCard(event:getCostData(self))
    room:setPlayerMark(player, "fengsui_heg__wumei_using", 0)
    if player:getMark("fengsui_heg__wumei_obtained") > 0 then
      room:setPlayerMark(player, "fengsui_heg__wumei_free-turn", 1)
    end
    room:setPlayerMark(player, "fengsui_heg__wumei_obtained", 0)
  end,
})

wumei:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:getMark("fengsui_heg__wumei_using") == 0 then return false end
    return table.find(data, function(move)
      return move.to == player and move.toArea == Card.PlayerHand and table.find(move.moveInfo, function(info)
        return isCurio(Fk:getCardById(info.cardId))
      end)
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__wumei_obtained", 1)
  end,
})

wumei:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return player:getMark("fengsui_heg__wumei_free-turn") > 0
  end,
})

return wumei
