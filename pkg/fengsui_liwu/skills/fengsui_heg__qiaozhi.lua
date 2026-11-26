local qiaozhi = fk.CreateSkill {
  name = "fengsui_heg__qiaozhi",
}

local FIRST = "fengsui_heg__qiaozhi_first-turn"

-- 取当前结算的使用牌的使用者：使用牌在结算后由 UseCard:clear 从处理区移入弃牌堆，
-- 这一步 moveCards 未指定 from，故 move.from 为 nil，需回溯最近的 UseCard 事件。
local function getUseFrom(room)
  local ev = room.logic:getMostRecentEvent(GameEvent.UseCard)
  if ev and ev.data then return ev.data.from end
  ev = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
  if ev and ev.data then return ev.data.from end
  return nil
end

-- 本次移动中「你的牌因使用或弃置而进入弃牌堆」的牌 id（不区分颜色）。
-- 弃置：move.from == player 且 ReasonDiscard（从手牌/装备直接进弃牌堆）。
-- 使用：ReasonUse 且 move.from == nil 且牌来自 Processing（结算后进弃牌堆），
--       此时用 getUseFrom 确认使用者是本人。
local function getEnteredDiscardIds(player, data)
  local room = player.room
  local useFrom = getUseFrom(room)
  local ids = {}
  for _, move in ipairs(data) do
    if move.toArea == Card.DiscardPile then
      local hit = false
      if move.moveReason == fk.ReasonDiscard and move.from == player then
        hit = true
      elseif move.moveReason == fk.ReasonUse and move.from == nil and useFrom == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.Processing then
            hit = true
            break
          end
        end
      end
      if hit then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
  end
  return ids
end

local function getEnteredDiscardRedIds(player, data)
  local ids = getEnteredDiscardIds(player, data)
  local redIds = {}
  for _, id in ipairs(ids) do
    local card = Fk:getCardById(id)
    if card and card.color == Card.Red then
      table.insertIfNeed(redIds, id)
    end
  end
  return redIds
end

qiaozhi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(qiaozhi.name) or player.dead then return false end
    if player:getMark(FIRST) > 0 then return false end
    -- 本回合首次「你的牌因使用/弃置进入弃牌堆」：无论颜色都触发判定，
    -- 由 on_cost 消耗机会并按是否有红牌决定是否弹框。
    return #getEnteredDiscardIds(player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    -- 机会用掉：即使本次无红牌、或玩家最终取消发动，之后本回合也不再触发
    room:setPlayerMark(player, FIRST, 1)
    local redIds = getEnteredDiscardRedIds(player, data)
    if #redIds == 0 then return false end
    return room:askToSkillInvoke(player, {
      skill_name = qiaozhi.name,
      prompt = "#fengsui_heg__qiaozhi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
