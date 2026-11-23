local qiaozhi = fk.CreateSkill {
  name = "fengsui_heg__qiaozhi",
}

local FIRST = "fengsui_heg__qiaozhi_first-turn"

-- 本回合首次因使用或弃置而有牌进入弃牌堆，若其中有红色牌，
-- 可展示所有这些红牌并置于牌堆底，然后与当前回合角色依次摸一张牌。
-- 只认 moveReason 为「使用/弃置」且 toArea 为弃牌堆的移动。
local function getEnteredDiscardRedIds(player, data)
  local room = player.room
  local redIds = {}
  for _, move in ipairs(data) do
    if move.from == player and move.toArea == Card.DiscardPile and
       (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard) then
      for _, info in ipairs(move.moveInfo) do
        local card = Fk:getCardById(info.cardId)
        if card and card.color == Card.Red then
          local dup = false
          for _, id in ipairs(redIds) do
            if id == info.cardId then dup = true break end
          end
          if not dup then table.insert(redIds, info.cardId) end
        end
      end
    end
  end
  return redIds
end

qiaozhi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(qiaozhi.name) or player.dead then return false end
    if player:getMark(FIRST) > 0 then return false end
    return #getEnteredDiscardRedIds(player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local redIds = getEnteredDiscardRedIds(player, data)
    if #redIds == 0 then
      -- 本回合首次因使用/弃置进弃牌堆却没有红牌，机会用掉
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
    local putIds = getEnteredDiscardRedIds(player, data)
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
