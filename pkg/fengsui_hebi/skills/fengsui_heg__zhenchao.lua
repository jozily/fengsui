local fuzheng = fk.CreateSkill { name = "fengsui_heg__zhenchao" }
local function takeBottom(room, skill)
  local id = room.draw_pile[#room.draw_pile]; if not id then return nil end
  room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, skill, nil, true); return id
end
local function askBottom(self, room, player, shown, judge)
  if player:getMark(self.name .. "-round") > 0 or not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__zhenchao"}) then return end
  room:setPlayerMark(player,self.name.."-round",1); local id=takeBottom(room,self.name); if not id then return end
  if judge then room:changeJudge{card=Fk:getCardById(id),skillName=self.name} end
  if shown and #shown>0 then room:obtainCard(player,shown,true,fk.ReasonPrey,player,self.name) end
  if #player:getCardIds("he")>0 and room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__zhenchao-bottom"}) then local c=room:askToChooseCard(player,{target=player,flag="he",skill_name=self.name}); room:moveCardTo(c,Card.DrawPile,nil,fk.ReasonPut,self.name,nil,true,player) end
end
fuzheng:addEffect(fk.FinishJudge,{can_trigger=function(self,_,target,player,data) return player:hasSkill(self.name) and target and data and data.card end,on_use=function(self,_,target,player,data) askBottom(self,player.room,player,{data.card:getEffectiveId()},true) end})
fuzheng:addEffect(fk.CardShown,{global=true,can_trigger=function(self,_,target,player,data) return player:hasSkill(self.name) and data and data.cardIds and #data.cardIds>0 end,on_use=function(self,_,target,player,data) askBottom(self,player.room,player,data.cardIds,false) end})
return fuzheng
