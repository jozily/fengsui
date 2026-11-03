-- 品流 · 旧版存档（不挂载任何武将，留作 Remake）
-- 旧效果：锁定技，当此武将牌与其他角色的武将牌易位后，易位前后控制此武将牌的角色
-- 各展示一张手牌。点数较大的角色选择一项：1.获得另一名角色展示的牌，然后摸两张牌；
-- 2.令另一名角色变更副将。
local H = require "packages.fengsui.hegemony_util"
local pinliu = fk.CreateSkill { name = "fengsui_heg__pinliuRemake", tags = {Skill.Compulsory} }
pinliu:addEffect(fk.AfterSkillEffect,{global=true,can_trigger=function(self,_,target,player) return target==player and player:hasShownSkill(self.name) and player:getMark("fengsui_heg__pinliuRemake_pending")~=0 end,on_use=function(self,_,_,player)
 local room=player.room; local other=room:getPlayerById(player:getMark("fengsui_heg__pinliuRemake_pending")); room:setPlayerMark(player,"fengsui_heg__pinliuRemake_pending",0); if not other or other.dead then return end
 local a,b=player:getCardIds("h"),other:getCardIds("h"); if #a>0 then room:showCards(a[1],player) end; if #b>0 then room:showCards(b[1],other) end; if #a==0 or #b==0 then return end
 local ca,cb=Fk:getCardById(a[1]),Fk:getCardById(b[1]); local chooser=player; if ca and cb and (cb.number or 0)>(ca.number or 0) then chooser=other end
 local choice=room:askToChoice(chooser,{choices={"fengsui_heg__pinliuRemake_gain","fengsui_heg__pinliuRemake_transform"},skill_name=self.name})
 if choice=="fengsui_heg__pinliuRemake_gain" then
   room:obtainCard(chooser, chooser == player and b[1] or a[1], true, fk.ReasonPrey, chooser, self.name)
   room:drawCards(chooser, 2, self.name)
 else
   H.transformGeneral(room, chooser == player and other or player, false, false, 1, self.name)
 end
end})
return pinliu
