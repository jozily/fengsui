local yinbing = fk.CreateSkill {
  name = "fengsui_heg__yinbing",
  tags = { Skill.Compulsory, Skill.DeputyPlace },
}

local function zhaoshuCards(player)
  return player:getPile("@[zhaoshu]")
end

yinbing:addEffect(fk.TargetConfirmed, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasShownSkill(yinbing.name) and data.use and data.card and
      #data.use.tos > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pile = zhaoshuCards(player)
    local ids = table.filter(pile, function(id)
      return Fk:getCardById(id).name ~= "heg_zhaoshu"
    end)
    if #ids > 0 then
      room:obtainCard(player, ids, true, fk.ReasonPrey, player, yinbing.name)
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
    else
      data.use.additionalEffectToPlayer = data.use.additionalEffectToPlayer or {}
      data.use.additionalEffectToPlayer[player] = (data.use.additionalEffectToPlayer[player] or 0) + 1
    end
  end,
})

return yinbing
