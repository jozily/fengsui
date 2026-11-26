local H = require "packages.fengsui.hegemony_util"

local yiju = fk.CreateSkill {
  name = "fengsui_heg__yiju",
  tags = { Skill.Compulsory },
}

-- 戍国牌的标记：锁定技依赖它判断"因戍国获得的牌"
yiju.SHUGUO_MARK = "@@fengsui_heg__shuguo"

local function isShuguoCard(card)
  return card and card:getMark(yiju.SHUGUO_MARK) > 0
end

-- 1) 目标限制：戍国牌只能指定与你势力不同的角色为目标（自己算同势力，不能指定）
yiju:addEffect(fk.TargetSpecifying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yiju.name) then return false end
    if data.cancelled then return false end
    if not data.card or not isShuguoCard(data.card) then return false end
    if not data.to then return false end
    -- 不只看当前 data.to：自己若出现在目标列表任意位置，也要取消
    -- （此前只判断 data.to == player + cancelCurrentTarget，会漏掉非首个目标）
    local tos = data.use and data.use.tos or {}
    for _, to in ipairs(tos) do
      if to == player then return true end
    end
    if data.to == player then return true end
    return H.compareKingdomWith(player, data.to) -- 同势力则取消
  end,
  on_cost = function(self) return true end,
  on_use = function(self, event, target, player, data)
    -- cancelCurrentTarget 只移除当前目标；cancelTarget 把自己从
    -- Undone/Done/use.tos 全部移除，确保自己不会留在目标里
    data:cancelTarget(player)
  end,
})

-- 2) 响应限制：戍国牌只能响应与你势力不同的角色使用/打出的牌（自己算同势力）
-- PreCardRespond 的 target 是响应者(张奂)；on_use 返回 true 亦会终止响应
yiju:addEffect(fk.PreCardRespond, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(yiju.name) then return false end
    if not data.card or not isShuguoCard(data.card) then return false end
    local ev = data.responseToEvent
    if not ev or not ev.from then return false end
    -- 响应自己使用的牌也算同势力，显式禁止
    if ev.from == player then return true end
    return H.compareKingdomWith(player, ev.from) -- 同势力使用的牌 -> 禁止响应
  end,
  on_cost = function(self) return true end,
  on_use = function(self, event, target, player, data)
    data:setNullified()
  end,
})

-- 3) 失去戍国牌后：你的回合内摸一张，回合外弃置一张
yiju:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(yiju.name) or player.dead then return false end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if isShuguoCard(card) and
             (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
            return true
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self) return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 清除这些牌上的戍国标记，避免重复触发
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if isShuguoCard(card) then room:setCardMark(card, yiju.SHUGUO_MARK, 0) end
        end
      end
    end
    if room.current == player then
      player:drawCards(1, yiju.name)
    elseif not player:isNude() then
      room:askToDiscard(player, {
        min_num = 1, max_num = 1, include_equip = true,
        skill_name = yiju.name, cancelable = false,
      })
    end
  end,
})

return yiju
