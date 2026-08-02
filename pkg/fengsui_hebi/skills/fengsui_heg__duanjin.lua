local H = require "packages.hegemony.util"

local duanjin = fk.CreateSkill{
  name = "fengsui_heg__duanjin",
}

duanjin:addEffect(H.GeneralRemoved, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and data.origName == "fengsui_heg__caoshi"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player)
    end)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__duanjin-choose",
      skill_name = duanjin.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { to = tos[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).to
    H.swapDeputy(player.room, player, to)
    H.addHegMark(player, "companion")
    H.addHegMark(to, "companion")
  end,
})

return duanjin
