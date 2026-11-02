local s = fk.CreateSkill {name = "fengsui_heg__anshi"}
s:addEffect("active", {
  card_num = 0, target_num = 1,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(s.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to, selected)
    return #selected == 0 and player:canUseTo(Fk:cloneCard("known_both"), to, {bypass_times = true})
  end,
  on_use = function(self, room, effect)
    local player, to = effect.from, effect.tos[1]
    local use = room:useVirtualCard("known_both", nil, player, to, s.name, true)
    if not use or to.dead or player.dead or not room:askToSkillInvoke(player,
      {skill_name = s.name, prompt = "#fengsui_heg__anshi-choice::" .. to.id}) then return end
    local choice = room:askToChoice(to, {choices = {"anshi_adjust", "anshi_extra_turn"}, skill_name = s.name})
    if choice == "anshi_adjust" then
      local n = to.hp - to:getHandcardNum()
      if n > 0 then to:drawCards(n, s.name)
      elseif n < 0 then room:askToDiscard(to, {min_num = -n, max_num = -n, include_equip = false,
        skill_name = s.name, cancelable = false}) end
    else
      player:gainAnExtraTurn(true, s.name)
      room:handleAddLoseSkills(player, "-" .. s.name)
    end
  end,
})
return s
