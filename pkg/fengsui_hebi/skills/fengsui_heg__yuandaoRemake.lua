local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yuandao = fk.CreateSkill{
  name = "fengsui_heg__yuandaoRemake",
}

yuandao:addEffect("arraysummon", { array_type = "formation" })

yuandao:addEffect(fk.CardUseFinished, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    if player == target and player.phase ~= Player.NotActive and data.card.type == Card.TypeTrick then
       for _, p in ipairs(player.room.alive_players) do
         if p:hasSkill(yuandao.name) and U.inSameQueue(p, target) then
           return true
         end
       end
    end
    return false
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "fengsui_heg__yuandaoRemake_active-turn", 1)
  end,
})

yuandao:addEffect(fk.PreCardUse, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__yuandaoRemake_active-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__yuandaoRemake_active-turn", 0)
    data.extraUse = true
  end,
})

return yuandao
