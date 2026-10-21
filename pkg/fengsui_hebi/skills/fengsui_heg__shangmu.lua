local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local Cmd = require "packages.hegemony.util"

local shangmu = fk.CreateSkill { name = "fengsui_heg__shangmu" }

shangmu:addEffect(fk.DamageInflicted, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and player:hasShownSkill(shangmu.name) and data and data.damage and
      data.damage >= target.hp + (target.shield or 0)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = shangmu.name, prompt = "#fengsui_heg__shangmu-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local place = U.getSkillPlace(player, shangmu.name)
    if place ~= nil and ((place and player.deputyGeneral == "anjiang") or
        (not place and player.general == "anjiang")) then
      player:revealGeneral(place)
    end
    local tos = table.filter(room.alive_players, function(p) return p ~= target end)
    local commandData
    if #tos > 0 then
      local _, result = Cmd.askToCommand(target, { tos = tos, skill_name = shangmu.name })
      commandData = result
    end
    local selected = table.filter(commandData and commandData.succeed_list or {}, function(p)
      return p and p:isAlive()
    end)
    if #selected > 0 then
      local chosen = #selected == 1 and selected[1] or room:askToChoosePlayers(player, {
        targets = selected, min_num = 1, max_num = 1, skill_name = shangmu.name,
        prompt = "#fengsui_heg__shangmu-source", cancelable = false,
      })[1]
      if chosen then data.from = chosen end
    end
    if target == player and H.allGeneralsRevealed(player) then
      local skillPlace = U.getSkillPlace(player, shangmu.name)
      if skillPlace ~= nil then player:hideGeneral(skillPlace) end
    end
  end,
})

return shangmu
