local H = require "packages.fengsui.hegemony_util"
local pinliu = fk.CreateSkill { name = "fengsui_heg__pinliu" }
pinliu:addEffect(fk.AfterSkillEffect,{global=true,can_trigger=function(self,_,target,player) return target==player and player:hasSkill(self.name) and player:getMark("fengsui_heg__pinliu_pending")~=0 end,on_use=function(self,_,_,player)
 local room=player.room; local other=room:getPlayerById(player:getMark("fengsui_heg__pinliu_pending")); room:setPlayerMark(player,"fengsui_heg__pinliu_pending",0); if not other or other.dead then return end
 local a,b=player:getCardIds("h"),other:getCardIds("h"); if #a>0 then room:showCards(a[1],player) end; if #b>0 then room:showCards(b[1],other) end; if #a==0 or #b==0 then return end
 local ca,cb=Fk:getCardById(a[1]),Fk:getCardById(b[1]); local chooser=player; if ca and cb and (cb.number or 0)>(ca.number or 0) then chooser=other end
 local choice=room:askToChoice(chooser,{choices={"fengsui_heg__pinliu_gain","fengsui_heg__pinliu_transform"},skill_name=self.name})
 if choice=="fengsui_heg__pinliu_gain" then room:obtainCard(chooser==player and player or other,chooser==player and b[1] or a[1],true,fk.ReasonPrey,chooser,self.name); room:drawCards(chooser==player and other or player,1,self.name) else H.transformGeneral(room,chooser==player and other or player,false,false,1,self.name); room:drawCards(chooser==player and other or player,2,self.name) end
end})
return pinliu
