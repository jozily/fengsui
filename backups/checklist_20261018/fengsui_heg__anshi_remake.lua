local s = fk.CreateSkill { name = "fengsui_heg__anshi" }

local function hiddenChoices(target)
  local choices = {}
  if target.general == "anjiang" then table.insert(choices, "anshi_reveal_main") end
  if target.deputyGeneral == "anjiang" then table.insert(choices, "anshi_reveal_deputy") end
  return choices
end

s:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasShownSkill(s.name)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room:getAlivePlayers(), min_num = 1, max_num = 1,
      skill_name = s.name, prompt = "#fengsui_heg__anshi-target", cancelable = true,
    })
    if #tos == 0 then return false end
    event:setCostData(self, { to = tos[1] })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    if not to or to.dead then return end
    local use = room:useVirtualCard("known_both", nil, player, to, s.name, true, {
      fengsui_heg__anshi = true,
    })
    if not use or to.dead then return end
    local choices = hiddenChoices(to)
    table.insert(choices, "anshi_adjust")
    local choice = room:askToChoice(to, { choices = choices, skill_name = s.name })
    if choice == "anshi_adjust" then
      local n = to:getMaxCards() - to:getHandcardNum()
      if n > 0 then to:drawCards(n, s.name)
      elseif n < 0 then room:askToDiscard(to, { min_num = -n, max_num = -n, include_equip = false, skill_name = s.name, cancelable = false }) end
    else
      to:revealGeneral(choice == "anshi_reveal_deputy")
      if player:isAlive() then
        room:handleAddLoseSkills(player, "-" .. s.name)
        player:gainAnExtraTurn(true, s.name)
      end
    end
  end,
})

return s
