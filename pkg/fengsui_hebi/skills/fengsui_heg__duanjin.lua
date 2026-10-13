local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local duanjin = fk.CreateSkill{
  name = "fengsui_heg__duanjin",
}

local function addDuanjinEffect(triggerEvent)
duanjin:addEffect(triggerEvent, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and player:hasShownSkill(duanjin.name) and data.origName == "fengsui_heg__caoshi" and
      H.hasGeneral(player, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player) and
        H.hasGeneral(p, true)
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
    local cost = event:getCostData(self)
    local to = cost.to
    local room = player.room
    H.swapDeputy(room, player, to)
    H.addHegMark(player, "companion")
    H.addHegMark(to, "companion")
  end,
})
end

addDuanjinEffect(H.GeneralRemoved)
addDuanjinEffect(H.GeneralTransformed)

Fk:loadTranslationTable{
  ["#fengsui_heg__duanjin-choose"] = "断衿：选择一名同势力角色，与其副将易位",
}

return duanjin
