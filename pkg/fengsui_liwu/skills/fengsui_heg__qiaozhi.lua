local qiaozhi = fk.CreateSkill {
  name = "fengsui_heg__qiaozhi",
}

local FIRST = "fengsui_heg__qiaozhi_first-turn"

-- 本回合第一次失去牌时，若其中有红色牌，可展示所有这些红牌并置于牌堆底
qiaozhi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(qiaozhi.name) or player.dead then return false end
    if player:getMark(FIRST) > 0 then return false end
    -- 本回合尚未失去过牌：只要此次有牌从自己区域移出即进入结算
    for _, move in ipairs(data) do
      if move.from == player then return true end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local redIds = {}
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card and card.color == Card.Red and
             (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
             room:getCardArea(info.cardId) ~= Card.DrawPile then
            local dup = false
            for _, id in ipairs(redIds) do
              if id == info.cardId then dup = true break end
            end
            if not dup then table.insert(redIds, info.cardId) end
          end
        end
      end
    end
    if #redIds == 0 then
      -- 本回合第一次失去的牌中没有红牌，机会用掉
      room:setPlayerMark(player, FIRST, 1)
      return false
    end
    return room:askToSkillInvoke(player, {
      skill_name = qiaozhi.name,
      prompt = "#fengsui_heg__qiaozhi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, FIRST, 1)
    local putIds = {}
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card and card.color == Card.Red and
             (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
             room:getCardArea(info.cardId) ~= Card.DrawPile then
            local dup = false
            for _, id in ipairs(putIds) do
              if id == info.cardId then dup = true break end
            end
            if not dup then table.insert(putIds, info.cardId) end
          end
        end
      end
    end
    if #putIds > 0 then
      room:moveCards{
        ids = putIds, toArea = Card.DrawPile, drawPilePosition = -1,
        moveReason = fk.ReasonPut, skillName = qiaozhi.name, moveVisible = true,
      }
    end
    -- 与当前回合角色依次摸一张
    player:drawCards(1, qiaozhi.name)
    local cur = room.current
    if cur and cur:isAlive() and cur ~= player then
      cur:drawCards(1, qiaozhi.name)
    elseif cur == player then
      player:drawCards(1, qiaozhi.name)
    end
  end,
})

return qiaozhi
