local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yingmian = fk.CreateSkill{
  name = "fengsui_heg__yingmian",
}

yingmian:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingmian.name, true) and
      not H.allGeneralsRevealed(player)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = player.room.alive_players,
      prompt = "#fengsui_heg__yingmian-ask",
      skill_name = yingmian.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { to = tos[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    U.revealOneGeneral(player)
    if player.dead or to.dead then return end

    local command = H.askToStartCommand(player, { skill_name = yingmian.name })
    if not command or player.dead or to.dead then return end
    local command_data = {
      tos = {to},
      from = player,
      command = command,
      skillName = yingmian.name,
    }
    if H.Command(command_data) then
      local executor = command_data.succeed_list[#command_data.succeed_list]
      if executor and executor:isAlive() then
        executor:drawCards(2, yingmian.name)
      end
    elseif player:isAlive() and to:isAlive() and not to:isNude() then
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = yingmian.name,
      })
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
})

return yingmian
