local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local ranlv = fk.CreateSkill { name = "fengsui_heg__ranlv" }
ranlv:addEffect(fk.Damaged, { can_trigger = function(self, _, target, player, data) return target ~= nil and target ~= player and player:hasSkill(self.name) and H.getGeneralsRevealedNum(player) == 2 and data and data.card and data.card:isCommonTrick() and data.from end,
    on_use = function(self, _, target, player)
      local room = player.room
      local place = Util.getSkillPlace(player, self.name)
      if place ~= nil then player:hideGeneral(place) end
      player:setChainState(true); target:setChainState(true)
      if player:getMark("fengsui_heg__ranlv_used") > 0 then
        local tos = table.filter(room.alive_players, function(p) return p ~= player and H.compareKingdomWith(p, player) end)
        if #tos > 0 then H.askToHebiOrTransform(room, room:askToChoosePlayers(player, { targets = tos, min_num = 1, max_num = 1, skill_name = self.name })[1], self.name, false) end
      else room:setPlayerMark(player, "fengsui_heg__ranlv_used", 1) end
    end })

return ranlv
