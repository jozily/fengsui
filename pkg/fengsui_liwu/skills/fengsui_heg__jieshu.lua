local U = require "packages.fengsui.pkg.fengsui_liwu.util"

local jieshu = fk.CreateSkill{
  name = "fengsui_heg__jieshu",
}

local function isCurio(card)
  return card and card.type == Card.TypeEquip and card.package and card.package.name == "nine_variations"
end

local function sameTargetIds(first, second)
  if type(first) ~= "table" or type(second) ~= "table" or #first ~= #second then return false end
  return table.every(first, function(id) return table.contains(second, id) end)
end

local function getLegalTargetIds(player, card)
  return table.map(card:getAvailableTargets(player, { bypass_times = true }), function(p) return p.id end)
end

local function getMatchingTrickNames(player, targetIds)
  return table.filter(U.getNationalCardNames({ "trick" }), function(name)
    return sameTargetIds(getLegalTargetIds(player, Fk:cloneCard(name)), targetIds)
  end)
end

local function releasesLock(player, card, targetIds)
  return isCurio(card) or
    (not card:isVirtual() and sameTargetIds(targetIds, getLegalTargetIds(player, card)))
end

local function clearJieshu(room, player, releaseId)
  room:setPlayerMark(player, "@fengsui_heg__jieshu", 0)
  room:setPlayerMark(player, "fengsui_heg__jieshu_legal_targets", 0)
  for _, label in ipairs(player:getTableMark("@fengsui_heg__jieshu_name")) do
    room:removeTableMark(player, "@fengsui_heg__jieshu_name", label)
  end
  -- 解除限制的这张牌本身延迟到下一张牌才能再次触发
  room:setPlayerMark(player, "fengsui_heg__jieshu_released_id", releaseId or 0)
end

jieshu:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(jieshu.name) or player:getMark("@fengsui_heg__jieshu") > 0 or
      player.room.current == nil or #data.tos == 0 then
      return false
    end
    -- 刚解除限制的那张牌不能立即再触发，从下一张牌起恢复
    if player:getMark("fengsui_heg__jieshu_released_id") == data.card:getEffectiveId() then
      return false
    end
    local targetIds = getLegalTargetIds(player, data.card)
    return #targetIds > 0 and #getMatchingTrickNames(player, targetIds) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local targetIds = getLegalTargetIds(player, data.card)
    local names = getMatchingTrickNames(player, targetIds)
    local use = player.room:askToUseVirtualCard(player, {
      name = names,
      skill_name = jieshu.name,
      prompt = "#fengsui_heg__jieshu",
      cancelable = true,
      skip = true,
      extra_data = { bypass_times = true },
    })
    if use then
      event:setCostData(self, { use = use, targetIds = targetIds })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    room:setPlayerMark(player, "@fengsui_heg__jieshu", 1)
    room:setPlayerMark(player, "fengsui_heg__jieshu_legal_targets", cost.targetIds)
    room:setPlayerMark(player, "fengsui_heg__jieshu_released_id", 0)
    room:addTableMark(player, "@fengsui_heg__jieshu_name", Fk:translate(data.card.name))
    cost.use.extraUse = true
    room:useCard(cost.use)
  end,
})

jieshu:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    if target ~= player then return false end
    if player:getMark("@fengsui_heg__jieshu") > 0 then
      local targetIds = player:getMark("fengsui_heg__jieshu_legal_targets")
      return targetIds ~= 0 and releasesLock(player, data.card, targetIds)
    end
    -- 未处于失效状态时，顺带清理过期的延迟标记
    return player:getMark("fengsui_heg__jieshu_released_id") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    if player:getMark("@fengsui_heg__jieshu") > 0 then
      clearJieshu(player.room, player, data.card:getEffectiveId())
    else
      player.room:setPlayerMark(player, "fengsui_heg__jieshu_released_id", 0)
    end
  end,
})

jieshu:addTest(function(room, me)
  lu.assertTrue(sameTargetIds({ 1, 2, 3 }, { 3, 1, 2 }))
  lu.assertFalse(sameTargetIds({ 1, 2 }, { 1, 3 }))
  lu.assertFalse(sameTargetIds({ 1 }, { 1, 2 }))
  local duelTargets = getLegalTargetIds(me, Fk:cloneCard("duel"))
  local archeryTargets = getLegalTargetIds(me, Fk:cloneCard("archery_attack"))
  lu.assertTrue(#duelTargets > 0)
  lu.assertTrue(sameTargetIds(duelTargets, archeryTargets))
  lu.assertTrue(table.contains(getMatchingTrickNames(me, duelTargets), "archery_attack"))
  lu.assertTrue(isCurio(Fk:cloneCard("serpent_slayer_sword")))
end)

return jieshu
