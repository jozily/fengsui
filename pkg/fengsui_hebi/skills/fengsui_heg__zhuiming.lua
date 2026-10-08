local H = require "packages.fengsui.hegemony_util"
local zhuiming = fk.CreateSkill { name = "fengsui_heg__zhuiming" }
zhuiming.hidden = true
zhuiming:addEffect(fk.Death,{global=true,can_trigger=function(self,_,target,player) return target and player:hasSkill(self.name) and H.compareKingdomWith(player,target) and target:getMark("fengsui_heg__bingyao_target")>0 end,on_use=function(self,_,target,player) local room=player.room; room:setPlayerMark(target,"fengsui_heg__bingyao_target",0); room:loseHp(player,1); if player.deputyGeneral~="anjiang" then player:hideGeneral(true) end; H.transformGeneral(room,player,false,false,1,self.name) end})
return zhuiming
