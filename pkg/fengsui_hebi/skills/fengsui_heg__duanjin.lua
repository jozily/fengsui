local H = require "packages.fengsui.pkg.fengsui_hebi.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local duanjin = fk.CreateSkill{
  name = "fengsui_heg__duanjin",
}

duanjin:addEffect(H.GeneralRemoved, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and data.origName == "fengsui_heg__caoshi" and
      H.getActualGeneral(player, not data.isDeputy) ~= ""
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player) and
        H.getActualGeneral(p, not data.isDeputy) ~= ""
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
      event:setCostData(self, { to = tos[1], is_deputy = not data.isDeputy })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost = event:getCostData(self)
    local to = cost.to
    local room = player.room
    if cost.is_deputy then
      H.swapDeputy(room, player, to)
    else
      if not U.swapGenerals(room, player) or not U.swapGenerals(room, to) then return end
      H.swapDeputy(room, player, to)
      U.swapGenerals(room, player)
      U.swapGenerals(room, to)
    end
    H.addHegMark(player, "companion")
    H.addHegMark(to, "companion")
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__duanjin-choose"] = "断衿：选择一名同势力角色，与其对应位置的武将牌易位",
}

return duanjin
