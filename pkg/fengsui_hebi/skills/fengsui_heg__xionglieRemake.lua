local xionglie = fk.CreateSkill{
  name = "fengsui_heg__xionglieRemake",
  tags = { Skill.Compulsory },
}

xionglie:addEffect(fk.TargetConfirming, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xionglie.name) or data.from ~= player or target == player or
      (target.general ~= "anjiang" and target.deputyGeneral ~= "anjiang") then
      return false
    end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not use_event then return false end
    local uses = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
      return e.data.from == player
    end, Player.HistoryRound)
    return #uses == 1 and uses[1].id == use_event.id
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsive = true
  end,
})

xionglie:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xionglie.name) and
      player:getMark("fengsui_heg__xionglieRemake_damage-round") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__xionglieRemake_damage-round", 1)
    if data.to and data.to.gender == General.Female then
      data:changeDamage(1)
    end
  end,
})

return xionglie
