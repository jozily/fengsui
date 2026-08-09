local xionglie = fk.CreateSkill{
  name = "fengsui_heg__xionglie",
  tags = { Skill.Compulsory },
}

local function sameRevealState(first, second)
  return first and second and
    (first.general == "anjiang") == (second.general == "anjiang") and
    (first.deputyGeneral == "anjiang") == (second.deputyGeneral == "anjiang")
end

xionglie:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xionglie.name) and data.to and
      sameRevealState(player, data.to)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsive = true
  end,
})

xionglie:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xionglie.name) and data.to and
      not sameRevealState(player, data.to)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return xionglie
