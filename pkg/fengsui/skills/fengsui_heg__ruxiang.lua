local ruxiang = fk.CreateSkill{
  name = "fengsui_heg__ruxiang",
}

ruxiang:addEffect(fk.GeneralRevealed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(ruxiang.name) then return false end
    return table.find(data, function(general_name)
      local general = Fk.generals[general_name]
      return general and table.contains(general:getSkillNameList(true), ruxiang.name)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseCard(player, {
      skill_name = ruxiang.name,
      pattern = ".",
      prompt = "#fengsui_heg__ruxiang-use",
      cancelable = true,
      extra_data = {bypass_times = true},
    })
    if use then
      event:setCostData(self, {use = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = event:getCostData(self).use
    use.extraUse = true
    player.room:useCard(use)
  end,
})

local function recastSpec(trigger_condition)
  return {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return trigger_condition(target, player, data) and player:hasSkill(ruxiang.name) and
      not data.fengsui_heg__ruxiang_recast and data.damage > 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = math.min(data.damage, #player:getCardIds("he")),
      include_equip = true,
      skill_name = ruxiang.name,
      prompt = "#fengsui_heg__ruxiang-recast:::" .. data.damage,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.fengsui_heg__ruxiang_recast = true
    player.room:recastCard(event:getCostData(self).cards, player, ruxiang.name)
  end,
  }
end

ruxiang:addEffect(fk.Damaged, recastSpec(function(target, player, data)
  return target == player
end))
ruxiang:addEffect(fk.Damage, recastSpec(function(target, player, data)
  return target == player
end))

return ruxiang
