local H = require "packages.fengsui.hegemony_util"

local fengji = fk.CreateSkill{name = "fengsui_limited_heg__fengji"}

Fk:loadTranslationTable{
  ["fengsui_limited_heg__fengji"] = "风纪",
  [":fengsui_limited_heg__fengji"] = "当其他同势力角色受到伤害后，若伤害来源在你的攻击范围内，你可以弃置一张装备牌，视为对其使用一张雷【杀】。",
  ["#fengsui_limited_heg__fengji-discard"] = "风纪：弃置一张装备牌，视为对 %dest 使用一张雷【杀】",
}

fengji:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local from = data.from
    if not target or target == player or not player:hasSkill(fengji.name) or
      not H.compareKingdomWith(player, target) or not from or from.dead or
      not player:inMyAttackRange(from) then return false end
    local slash = Fk:cloneCard("thunder__slash")
    return player:canUseTo(slash, from, { bypass_times = true }) and table.find(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).type == Card.TypeEquip and not player:prohibitDiscard(id)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1, max_num = 1, include_equip = true,
      pattern = ".|.|.|.|.|equip", skill_name = fengji.name,
      prompt = "#fengsui_limited_heg__fengji-discard::" .. data.from.id,
      cancelable = true, skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards, tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room, cost = player.room, event:getCostData(self)
    room:throwCard(cost.cards, fengji.name, player, player)
    if player:isAlive() and cost.tos[1]:isAlive() then
      room:useVirtualCard("thunder__slash", nil, player, cost.tos[1], fengji.name, true,
        { bypass_times = true, extraUse = true })
    end
  end,
})

return fengji
