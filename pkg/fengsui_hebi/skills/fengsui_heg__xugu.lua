local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local xugu = fk.CreateSkill{
  name = "fengsui_heg__xugu",
}

local function kingdom(player)
  return H.getKingdom(player)
end

local function requiredKingdoms(player)
  local result = {}
  local room = player.room or Fk:currentRoom()
  if not room then return result end
  for _, p in ipairs(room.alive_players) do
    if p ~= player then
      local k = kingdom(p)
      if k and k ~= "unknown" then table.insertIfNeed(result, k) end
    end
  end
  return result
end

xugu:addEffect("active", {
  anim_type = "control",
  prompt = "#fengsui_heg__xugu",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 99,
  can_use = function(self, player)
    return player:usedSkillTimes(xugu.name, Player.HistoryPhase) == 0 and
      H.getGeneralsRevealedNum(player) > 0 and #requiredKingdoms(player) > 0
  end,
  target_filter = function(self, player, to_select, selected)
    local k = kingdom(to_select)
    return to_select ~= player and k ~= "unknown" and not table.find(selected, function(p)
      return kingdom(p) == k
    end)
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected == #requiredKingdoms(player)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local command = H.askToStartCommand(player, {skill_name = xugu.name})
    if not command then return end
    H.doHideGeneral(room, player, player, xugu.name)
    room:sortByAction(effect.tos)
    for _, target in ipairs(effect.tos) do
      if target:isAlive() then
        local choices = {"xugu_draw_damage"}
        if H.getGeneralsRevealedNum(target) < 2 then table.insert(choices, 1, "xugu_command_reveal") end
        local choice = room:askToChoice(target, {
          choices = choices,
          skill_name = xugu.name,
          prompt = "#fengsui_heg__xugu-choice::" .. player.id,
        })
        if choice == "xugu_command_reveal" then
          H.Command{
            tos = {target},
            from = player,
            command = command,
            skillName = xugu.name,
            forced = true,
          }
          if target:isAlive() then U.revealOneGeneral(target) end
        else
          local n = H.getGeneralsRevealedNum(target)
          if n > 0 then target:drawCards(n, xugu.name) end
          if target:isAlive() and player:isAlive() then
            room:damage{from = player, to = target, damage = 1, skillName = xugu.name}
          end
        end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__xugu"] = "虚淈：每个已确定势力各选择一名其他角色",
  ["#fengsui_heg__xugu-choice"] = "虚淈：请选择执行军令并明置，或摸牌并受到 %dest 造成的伤害",
  ["xugu_command_reveal"] = "执行军令，然后明置一张武将牌",
  ["xugu_draw_damage"] = "摸已明置武将牌数张牌并受到1点伤害",
}

return xugu
