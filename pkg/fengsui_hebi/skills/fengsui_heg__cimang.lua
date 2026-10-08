local cimang = fk.CreateSkill { name = "fengsui_heg__cimang" }
cimang:addEffect(fk.GeneralShown, { can_trigger=function(self,_,target,player) return target==player and player:hasSkill(self.name) end, on_use=function(self,_,_,player)
 local room=player.room; if not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__cimang-invoke"}) then return end
 local ids=room:askToDiscard(player,{min_num=0,max_num=#player:getCardIds("he"),include_equip=true,skill_name=self.name,cancelable=true}); if type(ids)~="table" or #ids==0 then return end
 local red,black,judged={},{},{}
 for _=1,#ids do local judge={who=player,reason=self.name,pattern=".",skipDrop=true}; room:judge(judge); local c=judge.card; if c then table.insert(judged,c.id); table.insert(c.color==Card.Red and red or black,c.id) end end
 local chosen=(#red>=#black) and red or black; if #chosen>0 then room:obtainCard(player,chosen,true,fk.ReasonJustMove,nil,self.name) end
 local rest=table.filter(judged,function(id) return not table.contains(chosen,id) end); if #rest>0 then room:moveCards{ids=rest,toArea=Card.DrawPile,moveReason=fk.ReasonPut,skillName=self.name,drawPilePosition=-1} end
end})
return cimang
