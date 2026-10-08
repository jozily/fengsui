local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local qiju = fk.CreateSkill { name = "fengsui_heg__qiju", tags = { Skill.Limited } }
qiju:addEffect("active", {card_num=0,target_num=0,can_use=function(self,p) return p:getMark("fengsui_heg__qiju_used")==0 end,card_filter=Util.FalseFunc,target_filter=Util.FalseFunc,on_use=function(self,room,effect)
 local p=effect.from; room:setPlayerMark(p,"fengsui_heg__qiju_used",1); local n=H.getGeneralsRevealedNum(p); for _,x in ipairs(room.alive_players) do if x~=p and H.getGeneralsRevealedNum(x)~=n then room:changeKingdom(x,"unknown",true) end end
end})
qiju:addEffect(fk.CardUsing,{global=true,can_trigger=function(self,_,target,player,data) return player:hasSkill(self.name) and player:getMark("fengsui_heg__qiju_used")>0 and target and target~=player and H.getGeneralsRevealedNum(target)==H.getGeneralsRevealedNum(player) and data and data.card and data.card.type==Card.TypeBasic and data.tos and table.find(data.tos,function(x) return x.kingdom=="unknown" end)~=nil and target:getMark("fengsui_heg__qiju-turn")==0 end,on_use=function(self,_,target,player,data)
 local room=player.room; local names=Util.getNationalCardNames({basic=true}); if #names==0 or not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__qiju-use"}) then return end; local name=room:askToChoice(player,{choices=names,skill_name=self.name}); local v=Fk:cloneCard(name,data.card.suit,data.card.number); v.skillName=self.name; data.card=v; room:setPlayerMark(target,"fengsui_heg__qiju-turn",1)
end})
return qiju
