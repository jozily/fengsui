local H = require "packages.fengsui.hegemony_util"

local xugu = fk.CreateSkill{
  name = "fengsui_heg__xuguRemake",
}

xugu:addEffect("active", {
  anim_type = "control",
  prompt = "#fengsui_heg__xuguRemake",
  can_use = function(self, player)
    return player:usedSkillTimes(xugu.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  min_target_num = 1,
  max_target_num = 999,
  target_filter = function(self, player, to_select, selected)
    return true
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local command = H.askToStartCommand(player, {skill_name = xugu.name})
    if not command then return end
    local shown, show_players, command_players = {}, {}, {}

    for _, target in ipairs(effect.tos) do
      if target:isAlive() then
        local choices = {"xugu_do_command"}
        if H.allGeneralsRevealed(target) and not target:isKongcheng() then
          table.insert(choices, 1, "xugu_show_hide")
        end
        local choice = room:askToChoice(target, {
          choices = choices,
          skill_name = xugu.name,
          prompt = "#fengsui_heg__xuguRemake-choice::" .. player.id,
        })
        if choice == "xugu_show_hide" then
          local id = room:askToChooseCard(target, {
            target = target,
            flag = "h",
            prompt = "#fengsui_heg__xuguRemake-show",
            skill_name = xugu.name,
          })
          table.insert(shown, id)
          table.insert(show_players, target)
          room:showCards({id}, target)
          target:hideGeneral(false)
          target:hideGeneral(true)
        else
          table.insert(command_players, target)
          H.Command{
            tos = {target},
            from = player,
            command = command,
            skillName = xugu.name,
            forced = true,
          }
        end
      end
    end

    if #show_players <= #command_players then
      local available = table.filter(shown, function(id)
        return room:getCardArea(id) == Card.PlayerHand
      end)
      if player:isAlive() and #available > 0 then
        room:askToUseRealCard(player, {
          pattern = available,
          expand_pile = available,
          skill_name = xugu.name,
          prompt = "#fengsui_heg__xuguRemake-use",
          cancelable = false,
        })
      end
      return
    end

    for _, source in ipairs(command_players) do
      local candidates = table.filter(show_players, function(p) return p:isAlive() end)
      if source:isAlive() and #candidates > 0 then
        local min_distance = math.min(table.unpack(table.map(candidates, function(p)
          return source:distanceTo(p)
        end)))
        candidates = table.filter(candidates, function(p)
          return source:distanceTo(p) == min_distance
        end)
        local victim = candidates[1]
        if #candidates > 1 then
          victim = room:askToChoosePlayers(source, {
            targets = candidates,
            min_num = 1,
            max_num = 1,
            skill_name = xugu.name,
            prompt = "#fengsui_heg__xuguRemake-damage",
            cancelable = false,
          })[1]
        end
        room:damage{from = source, to = victim, damage = 1, skillName = xugu.name}
      end
    end
  end,
})

return xugu
