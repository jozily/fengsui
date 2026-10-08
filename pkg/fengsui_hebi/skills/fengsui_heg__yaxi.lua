local yaxi = fk.CreateSkill { name = "fengsui_heg__yaxi" }
yaxi:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target ~= player and player:hasSkill(self.name)
      and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
      and data and data.skill and target:usedSkillTimes(data.skill.name, Player.HistoryTurn) > 0
      and target.general ~= "anjiang" and target.deputyGeneral ~= "anjiang"
  end,
  on_use = function(self, _, target, player, data)
    if not data or not data.skill then return end
    local room = player.room
    room:drawCards(target, 1, self.name)
    if target.general ~= "anjiang" then target:hideGeneral(false) else target:hideGeneral(true) end
    room:setPlayerMark(target, "fengsui_heg__yaxi_disabled-turn", 1)
  end,
})
yaxi:addEffect(fk.GeneralRevealed, {
  global = true,
  can_trigger = function(self, _, target, player, data) return target and target:getMark("fengsui_heg__yaxi_disabled-turn") > 0 and data and (data.m or data.d) end,
  on_use = function(self, _, target, player, data)
    if data.m and target.general ~= "anjiang" then target:hideGeneral(false) end
    if data.d and target.deputyGeneral ~= "anjiang" then target:hideGeneral(true) end
  end,
})

yaxi:addEffect(fk.TurnStart, { global = true, on_use = function(self, _, target) target.room:setPlayerMark(target, "fengsui_heg__yaxi_disabled-turn", 0) end })
return yaxi
