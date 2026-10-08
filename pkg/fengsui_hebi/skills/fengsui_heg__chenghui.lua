local H = require "packages.fengsui.hegemony_util"
local chenghui = fk.CreateSkill { name = "fengsui_heg__chenghui" }
chenghui.hidden = true
chenghui:addEffect(fk.AfterDying, { global = true,
  can_trigger = function(self, _, target, player) return target and player:hasSkill(self.name) and H.compareKingdomWith(player,target) and target:getMark("fengsui_heg__bingyao_target") > 0 end,
  on_use = function(self, _, target, player)
    local room=player.room
    room:setPlayerMark(target,"fengsui_heg__bingyao_target",0)
    room:setPlayerMark(target,"fengsui_heg__chenghui_extra-turn",1)
  end,
})
chenghui:addEffect(fk.TurnEnd, { global = true,
  can_trigger = function(self, _, target, player) return target and target:getMark("fengsui_heg__chenghui_extra-turn") > 0 and target:isAlive() end,
  on_use = function(self, _, target) local room=target.room; room:setPlayerMark(target,"fengsui_heg__chenghui_extra-turn",0); if target.general=="anjiang" then target:revealGeneral(false) end; if target.deputyGeneral=="anjiang" then target:revealGeneral(true) end; target:gainAnExtraPhase(Player.Play,self.name) end,
})
return chenghui
