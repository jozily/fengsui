local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local H = require "packages.fengsui.hegemony_util"
local qingsong = fk.CreateSkill {
  name = "fengsui_heg__qingsong",
}
local pendingMark = "fengsui_heg__qingsong_pending"
local pendingVisibleMark = "@fengsui_heg__qingsong_pending"
local function hasActualSkill(player)
  for _, isDeputy in ipairs({ false, true }) do
    local general = Fk.generals[H.getActualGeneral(player, isDeputy)]
    if general and table.contains(general:getSkillNameList(true), qingsong.name) then
      return true
    end
  end
  return false
end

local function canTriggerCard(card)
  return card and (card.type == Card.TypeBasic or card:isCommonTrick())
end

local function canUseRecorded(player, name)
  local card = Fk:cloneCard(name)
  local extra = { bypass_times = true, extraUse = true, bypass_distances = true }
  if not player:canUse(card, extra) then return false end
  return #card:getAvailableTargets(player, extra) > 0
end

qingsong:addEffect(fk.TargetConfirmed, {
  global = true,
  anim_type = "defensive",
  can_trigger = function(self, _, target, player, data)
    return target == player and hasActualSkill(player) and
      canTriggerCard(data and data.card) and not player:isKongcheng() and
      table.find(player:getCardIds("h"), function(id)
        local card = Fk:getCardById(id)
        return card.type ~= data.card.type and canTriggerCard(card)
      end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local card = data.card
    local candidates = table.filter(player:getCardIds("h"), function(id)
      local hand_card = Fk:getCardById(id)
      return hand_card.type ~= card.type and
        canTriggerCard(hand_card)
    end)
    local selected = U.chooseCardsFromList(player.room, player, candidates, 1, 1,
      "#fengsui_heg__qingsong-give", self.name, true)
    if #selected == 0 then return false end
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      skill_name = self.name,
      prompt = "#fengsui_heg__qingsong-to",
      cancelable = true,
    })
    if #tos == 0 then return false end
    event:setCostData(self, { card = selected[1], to = tos[1] })
    return true
  end,
  on_use = function(self, event, _, player)
    local room = player.room
    local cost = event:getCostData(self)
    local given = Fk:getCardById(cost.card, true)
    if not given or room:getCardOwner(cost.card) ~= player then return end
    room:moveCardTo(cost.card, Card.PlayerHand, cost.to, fk.ReasonGive,
      self.name, nil, true, player)
    -- 使用记录必须跨过当前阶段结束事件；使用 -turn 避免引擎在
    -- EventPhaseEnd 前自动清掉 -phase 标记。
    if not canTriggerCard(given) then return end
    room:addTableMark(player, pendingMark, given.trueName)
    room:addTableMarkIfNeed(player, pendingVisibleMark, given.trueName)
  end,
})

qingsong:addEffect(fk.TurnEnd, {
  global = true,
  is_delay_effect = true,
  priority = 20,
  can_trigger = function(self, _, target, player)
    -- 牌可能是在其他角色的回合交出；此处在当前回合结束时检查
    -- 青松拥有者的记录，而不是要求阶段角色就是青松拥有者。
    return target and #player:getTableMark(pendingMark) > 0
  end,
  on_cost = function(self, _, _, player)
    local room = player.room
    local invoke = room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#fengsui_heg__qingsong-use",
    })
    if not invoke then
      room:setPlayerMark(player, pendingMark, 0)
      room:setPlayerMark(player, pendingVisibleMark, 0)
    end
    return invoke
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local batches = 0
    while player:isAlive() and #player:getTableMark(pendingMark) > 0 and batches < 32 do
      batches = batches + 1
      local names = player:getTableMark(pendingMark)
      -- 先清空本批记录；取消、无合法目标或使用失败都不会残留到下回合。
      room:setPlayerMark(player, pendingMark, 0)
      room:setPlayerMark(player, pendingVisibleMark, 0)
      for _, name in ipairs(names) do
        if not player:isAlive() then break end
        local use = room:askToUseVirtualCard(player, {
          name = name,
          skill_name = self.name,
          prompt = "#fengsui_heg__qingsong-use",
          cancelable = false,
          skip = true,
          extra_data = { bypass_times = true, extraUse = true, bypass_distances = true },
        })
        if not use then
          local card = Fk:cloneCard(name)
          local extra = { bypass_times = true, extraUse = true, bypass_distances = true }
          if player:canUse(card, extra) then
            local tos = card:getDefaultTarget(player, extra)
            if tos and #tos > 0 then
              use = { from = player, tos = tos, card = card, extraUse = true }
            end
          end
        end
        if use and player:isAlive() then
          room:useCard(use)
          if player:isAlive() then player:drawCards(1, self.name) end
        end
      end
    end
    if player:isAlive() and #player:getTableMark(pendingMark) > 0 then
      room:setPlayerMark(player, pendingMark, 0)
      room:setPlayerMark(player, pendingVisibleMark, 0)
    end
  end,
})

return qingsong
