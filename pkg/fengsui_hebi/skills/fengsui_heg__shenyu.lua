local shenyu = fk.CreateSkill { name = "fengsui_heg__shenyu" }
shenyu:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and target:isAlive() and player:hasShownSkill(self.name) and
      target:getMark("fengsui_heg__shenyu-turn") == 0 and
      target:getMark("fengsui_heg__shenyu-discard") > target.hp
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__shenyu-invoke::" .. target.id })
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(target, "fengsui_heg__shenyu-turn", 1)
    local n = target:getHandcardNum() - target.hp
    if n > 0 then room:askToDiscard(target, { min_num = n, max_num = n, include_equip = false, cancelable = false, skill_name = self.name })
    elseif n < 0 then room:drawCards(target, -n, self.name) end
  end,
})
return shenyu
