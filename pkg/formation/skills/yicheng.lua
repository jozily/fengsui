local yicheng = fk.CreateSkill{
  name = "yicheng",
}

Fk:loadTranslationTable{
  ["yicheng"] = "疑城",
  [":yicheng"] = "当你或与你势力相同的角色使用【杀】指定目标后或成为【杀】的目标后，其可以摸一张牌，然后其弃置一张牌。",

  ["#yicheng-invoke"] = "疑城：你可以摸一张牌，然后弃置一张牌",

  ["$yicheng1"] = "不怕死，就尽管放马过来！",
  ["$yicheng2"] = "待末将布下疑城，以退曹贼。",
}

local H = require "packages.hegemony.util"

local spec = {
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = yicheng.name,
      prompt = "#yicheng-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target:drawCards(1, yicheng.name)
    if not target.dead then
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = yicheng.name,
        cancelable = false,
      })
    end
  end
}

yicheng:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yicheng.name) and
      (target == player or H.compareKingdomWith(target, player)) and data.card.trueName == "slash"
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use
})
yicheng:addEffect(fk.TargetSpecified, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(yicheng.name) and (target == player or H.compareKingdomWith(target, player)) and
      data.card.trueName == "slash" and data.firstTarget
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use
})

return yicheng
