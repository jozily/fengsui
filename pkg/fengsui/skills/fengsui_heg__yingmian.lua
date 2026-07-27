local H = require "packages.hegemony.util"

local yingmian = fk.CreateSkill{
  name = "fengsui_heg__yingmian",
}

yingmian:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingmian.name) and
      H.allGeneralsRevealed(player)
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
    H.doHideGeneral(room, player, player, yingmian.name)
    if player.dead or to.dead then return end

    local command = H.askToStartCommand(player, { skill_name = yingmian.name })
    if not command or player.dead or to.dead then return end
    if H.Command{
      tos = {to},
      from = player,
      command = command,
      skillName = yingmian.name,
    } then
      local revealed = H.getGeneralsRevealedNum(to)
      local x = 2 - revealed
      if to.general == "anjiang" then to:revealGeneral(false, true) end
      if to.deputyGeneral == "anjiang" then to:revealGeneral(true, true) end
      if x > 0 and to:isAlive() then to:drawCards(2 * x, yingmian.name) end
    end
  end,
})

return yingmian
