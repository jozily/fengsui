local H = require "packages.fengsui.hegemony_util"
local yuanyi = fk.CreateSkill{
  name = "fengsui_heg__yuanyi",
  tags = { Skill.Compulsory },
}

local function sameRevealState(first, second)
  return first and second and H.getGeneralsRevealedNum(first) == H.getGeneralsRevealedNum(second)
end

yuanyi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanyi.name) and
      sameRevealState(player, data.to)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

yuanyi:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuanyi.name) and
      sameRevealState(player, data.from)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return yuanyi
