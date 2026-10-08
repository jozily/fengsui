local quchi = fk.CreateSkill { name = "fengsui_heg__quchi" }
quchi:addEffect(fk.AskForRetrial,{global=true,can_trigger=function(self,_,target,player) return target and player:hasSkill(self.name) and player.general~="anjiang" and player.deputyGeneral~="anjiang" and #player.room:canMoveCardInBoard()>0 end,on_use=function(self,_,target,player,data)
 local room=player.room; if not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__quchi-invoke"}) then return end
 local tos=room:askToChooseToMoveCardInBoard(player,{prompt="#fengsui_heg__quchi-target",skill_name=self.name,cancelable=true}); if #tos~=2 then return end
 local moved=room:askToMoveCardInBoard(player,{target_one=tos[1],target_two=tos[2],skill_name=self.name}); if not moved then return end
 player:hideGeneral(player.deputyGeneral~="anjiang"); local old=data.card and data.card:getEffectiveId(); local v=Fk:cloneCard(data.card.name,moved.card.suit,moved.card.number); v.skillName=self.name; data.card=v
 if old and room:getCardArea(old)==Card.Processing then room:moveCardTo(old,Card.DiscardPile,nil,fk.ReasonJudge,self.name,nil,true,player) end
end})
return quchi
