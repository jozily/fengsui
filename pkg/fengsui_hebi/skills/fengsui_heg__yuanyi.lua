local yuanyi = fk.CreateSkill{
  name = "fengsui_heg__yuanyi",
  tags = { Skill.Compulsory },
}

local function sameRevealState(first, second)
  return first and second and
    (first.general == "anjiang") == (second.general == "anjiang") and
    (first.deputyGeneral == "anjiang") == (second.deputyGeneral == "anjiang")
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
