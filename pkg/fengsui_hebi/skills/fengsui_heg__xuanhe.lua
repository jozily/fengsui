local xuanhe = fk.CreateSkill{
  name = "fengsui_heg__xuanhe",
  tags = { Skill.Compulsory, Skill.MainPlace },
}

local type_mark = "fengsui_heg__xuanhe_types-turn"

xuanhe:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanhe.name) and
      player:usedSkillTimes(xuanhe.name, Player.HistoryTurn) == 0 and #data.tos > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    for _, to in ipairs(data.tos) do
      if to:isAlive() then
        player.room:addTableMarkIfNeed(to, type_mark, data.card.type)
      end
    end
  end,
})

xuanhe:addEffect(fk.TargetConfirming, {
  global = true,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(xuanhe.name) and data.from and data.from ~= player) then
      return false
    end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not use_event then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      return e.data.from == data.from
    end, Player.HistoryTurn)
    return #events == 1 and events[1].id == use_event.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
  end,
})

xuanhe:addEffect("prohibit", {
  global = true,
  prohibit_use = function(self, player, card)
    return table.contains(player:getTableMark(type_mark), card.type)
  end,
  prohibit_response = function(self, player, card)
    return table.contains(player:getTableMark(type_mark), card.type)
  end,
})

return xuanhe
