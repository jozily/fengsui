local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local Cmd = require "packages.hegemony.util"
local shangmu = fk.CreateSkill { name = "fengsui_heg__shangmu" }

shangmu:addEffect(fk.DamageInflicted, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and player:hasShownSkill(shangmu.name) and
      data and data.damage and data.damage >= (target.hp + (target.shield or 0))
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = shangmu.name,
      prompt = "#fengsui_heg__shangmu-invoke::" .. target.id,
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
    if #tos == 0 then return end
    local originalSource = data.from
    local ownerIncluded = table.contains(tos, player)
    local commandTargets = table.filter(tos, function(p) return p ~= player end)
    local succeed, commandData
    if #commandTargets > 0 then
      succeed, commandData = Cmd.askToCommand(player, {
        tos = commandTargets, skill_name = shangmu.name,
      })
    elseif ownerIncluded then
      local command = Cmd.askToStartCommand(player, { skill_name = shangmu.name })
      if command then commandData = { command = command, succeed_list = {} } end
    end
    local selected = commandData and commandData.succeed_list or {}
    -- 温峤本人执行军令时，军令发起方向改为原伤害来源指向温峤。
    if ownerIncluded and commandData and commandData.command then
      local ownerData = {
        tos = { player }, from = (originalSource and originalSource:isAlive()) and originalSource or player,
        command = commandData.command, skillName = shangmu.name,
      }
      if Cmd.Command(ownerData) then table.insert(selected, player) end
    end
    if succeed or #selected > 0 then
      if #selected > 1 then
        local tos = room:askToChoosePlayers(player, {
          targets = selected, min_num = 1, max_num = 1,
          skill_name = shangmu.name, prompt = "#fengsui_heg__shangmu-source",
          cancelable = false,
        })
        selected = tos
      end
      if selected and selected[1] then data.from = selected[1] end
    end
  end,
})
return shangmu
