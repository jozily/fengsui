local zhenchao = fk.CreateSkill { name = "fengsui_heg__zhenchao" }

local function available(self, player)
  return player:hasShownSkill(self.name) and
    player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
    #player.room.draw_pile > 0
end

local function putBottom(self, player)
  local room = player.room
  if player.dead or player:isNude() then return end
  local cards = room:askToCards(player, {
    min_num = 1, max_num = 1, include_equip = true, cancelable = true,
    skill_name = self.name, prompt = "#fengsui_heg__zhenchao-bottom",
  })
  if #cards > 0 then
    room:moveCards {
      ids = cards, from = player, toArea = Card.DrawPile,
      drawPilePosition = -1, moveReason = fk.ReasonPut,
      skillName = self.name, moveVisible = true,
    }
  end
end

zhenchao:addEffect(fk.AskForRetrial, {
  can_trigger = function(self, _, target, player, data)
    return target and data and data.card and available(self, player)
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__zhenchao",
    })
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    local id = room.draw_pile[#room.draw_pile]
    if not id then return end
    room:changeJudge {
      card = Fk:getCardById(id), player = player, data = data,
      skillName = self.name, exchange = true,
    }
    putBottom(self, player)
  end,
})

zhenchao:addEffect(fk.CardShown, {
  can_trigger = function(self, _, target, player, data)
    return target and available(self, player) and data and
      data.cardIds and #data.cardIds == 1
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__zhenchao",
    })
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local original = data.cardIds[1]
    local area = room:getCardArea(original)
    local source = data.from or target
    local id = room.draw_pile[#room.draw_pile]
    if not id then return end
    -- 先将底牌交到原牌所在区域，再取得原牌；后续展示事件读取替代牌。
    room:moveCards {
      ids = {id}, to = (area == Card.PlayerHand or area == Card.PlayerEquip) and source or nil, toArea = area,
      moveReason = fk.ReasonJustMove, skillName = self.name, moveVisible = true,
    }
    data.cardIds = {id}
    room:obtainCard(player, original, true, fk.ReasonPrey, player, self.name)
    putBottom(self, player)
  end,
})

return zhenchao
