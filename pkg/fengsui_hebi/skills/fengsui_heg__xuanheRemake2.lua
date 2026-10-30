local xuanhe = fk.CreateSkill{
  name = "fengsui_heg__xuanheRemake2",
  tags = { Skill.Compulsory, Skill.MainPlace },
}

local type_mark = "fengsui_heg__xuanheRemake2_types-turn"

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

Fk:loadTranslationTable{
  ["fengsui_heg__xuanheRemake2"] = "悬河·旧",
  [":fengsui_heg__xuanheRemake2"] = "主将技，锁定技，你计算体力上限时减少一个单独的阴阳鱼。当你于回合内首次使用牌指定目标后，所有目标本回合无法使用或打出与此牌类别相同的牌。其他角色使用牌指定你为目标后，若为其本回合使用的首张牌，取消之。",
}

return xuanhe
