local s = fk.CreateSkill { name = "fengsui_heg__anshi" }

local function undetermined(player)
  return player.kingdom == "unknown" or player.kingdom == "fengsui_neutral" or player.kingdom == "fengsui_neutralall"
end

local function generalKingdom(player, isDeputy)
  local mark = player:getMark(isDeputy and "__heg_deputy" or "__heg_general")
  local general = type(mark) == "string" and Fk.generals[mark] or nil
  return general and general.kingdom or nil
end

s:addEffect("active", {
  card_num = 0, target_num = 1,
  can_use = function(self, player) return player:usedSkillTimes(s.name, Player.HistoryPhase) == 0 end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    local use = room:useVirtualCard("known_both", nil, player, target, s.name, false, {
      fengsui_heg__anshi = true,
    })
    if player.dead or target.dead then return end
    local function adjustHand()
      local n = target:getMaxCards() - target:getHandcardNum()
      if n > 0 then
        target:drawCards(n, s.name)
      elseif n < 0 then
        room:askToDiscard(target, { min_num = -n, max_num = -n, include_equip = false, skill_name = s.name, cancelable = false })
      end
    end

    if not undetermined(target) or not (use and use.extra_data and use.extra_data.fengsui_heg__anshi_viewed_general) then
      adjustHand()
      return
    end
    local playerKingdom
    if player.general ~= "anjiang" then playerKingdom = Fk.generals[player.general].kingdom end
    if not playerKingdom and player.deputyGeneral ~= "anjiang" then playerKingdom = Fk.generals[player.deputyGeneral].kingdom end
    if not playerKingdom then
      adjustHand()
      return
    end
    local choices = {}
    if target.general == "anjiang" and generalKingdom(target, false) == playerKingdom then table.insert(choices, "anshi_reveal_main") end
    if target.deputyGeneral == "anjiang" and generalKingdom(target, true) == playerKingdom then table.insert(choices, "anshi_reveal_deputy") end
    if #choices == 0 then
      adjustHand()
      return
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(target, { choices = choices, skill_name = s.name })
    if choice == "Cancel" then return end
    target:revealGeneral(choice == "anshi_reveal_deputy")
    if target:isAlive() then target:gainAnExtraTurn(true, s.name) end
  end,
})

return s
