local qujian = fk.CreateSkill{
  name = "fengsui_heg__qujian",
}

qujian:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      not player:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(player:getCardIds("h"), self.name, player, player)
    local card = Fk:cloneCard("thunder__slash")
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and player:canUseTo(card, p, { bypass_times = true })
    end)
    if #targets > 0 then
      room:useVirtualCard("thunder__slash", nil, player, targets, self.name, true,
        { bypass_times = true })
    end
  end,
})

qujian:addEffect(fk.Damaged, {
  global = true, is_delay_effect = true,
  can_trigger = function(self, _, target, player, data)
    local card = data and data.card
    return data.from == player and card and table.contains(card.skillNames, qujian.name)
  end,
  on_use = function(self, _, target)
    target:setChainState(true)
  end,
})

return qujian
