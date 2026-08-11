local ruxiang = fk.CreateSkill{
  name = "fengsui_heg__ruxiang",
}

local function hasLegalTarget(player, card)
  if card.skill:getMinTargetNum() == 0 and not card.multiple_targets then return true end
  return table.find(player.room.alive_players, function(target)
    return player:canUseTo(card, target, {bypass_times = true})
  end) ~= nil
end

local function usableCardIds(player)
  return table.filter(player:getCardIds("h"), function(id)
    local card = Fk:getCardById(id)
    return card.trueName ~= "jink" and card.trueName ~= "nullification" and
      not player:prohibitUse(card) and player:canUse(card, {bypass_times = true}) and
      hasLegalTarget(player, card)
  end)
end

local function recastCost(self, event, player, damage)
  local max_num = math.min(damage, #player:getCardIds("he"))
  if max_num < 1 then return false end
  local cards = player.room:askToChooseCards(player, {
    target = player,
    min = 1,
    max = max_num,
    flag = "he",
    skill_name = ruxiang.name,
    prompt = "#fengsui_heg__ruxiang-recast:::" .. damage,
    cancelable = true,
  })
  if #cards > 0 then
    event:setCostData(self, {cards = cards})
    return true
  end
end

local function recastUse(self, event, player)
  player.room:recastCard(event:getCostData(self).cards, player, ruxiang.name)
end

ruxiang:addEffect(fk.GeneralRevealed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ruxiang.name) and #usableCardIds(player) > 0 and
      (data.m == "fengsui_heg__hanshou" or data.d == "fengsui_heg__hanshou")
  end,
  on_cost = function(self, event, target, player, data)
    local ids = usableCardIds(player)
    if #ids == 0 then return false end
    local use = player.room:askToUseCard(player, {
      skill_name = ruxiang.name,
      prompt = "#fengsui_heg__ruxiang-use",
      cancelable = true,
      pattern = tostring(Exppattern{ id = ids }),
      extra_data = {bypass_times = true, extraUse = true},
    })
    if use then
      event:setCostData(self, {use = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = event:getCostData(self).use
    use.extraUse = true
    use.extra_data = use.extra_data or {}
    use.extra_data.bypass_times = true
    player.room:useCard(use)
  end,
})

ruxiang:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ruxiang.name) and data.damage > 0 and
      #player:getCardIds("he") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return recastCost(self, event, player, data.damage)
  end,
  on_use = function(self, event, target, player, data)
    recastUse(self, event, player)
  end,
})

ruxiang:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(ruxiang.name) and data.damage > 0 and
      #player:getCardIds("he") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return recastCost(self, event, player, data.damage)
  end,
  on_use = function(self, event, target, player, data)
    recastUse(self, event, player)
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__ruxiang-use"] = "擩香：你可以使用一张牌（不计入次数）",
  ["#fengsui_heg__ruxiang-recast"] = "擩香：你可以重铸至多 %arg 张牌",
}

return ruxiang
