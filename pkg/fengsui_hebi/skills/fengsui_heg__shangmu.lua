local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local shangmu = fk.CreateSkill { name = "fengsui_heg__shangmu" }
shangmu:addEffect(fk.EnterDying, { global = true,
  can_trigger = function(self, _, target, player, data) return target ~= player and target and player:hasSkill(self.name) and not H.compareKingdomWith(player,target) and data and data.damage and data.damage.from ~= player end,
  on_use = function(self, _, target, player)
    local place = U.getSkillPlace(player, self.name)
    if place ~= nil and ((place and player.deputyGeneral == "anjiang") or (not place and player.general == "anjiang")) then player:revealGeneral(place) end
    local round = player.room:getTag("RoundCount") or 1
    player.room:setPlayerMark(player,"fengsui_heg__shangmu-round",round)
    player.room:setPlayerMark(target,"fengsui_heg__shangmu_reward",round*2)
  end,
})
return shangmu
