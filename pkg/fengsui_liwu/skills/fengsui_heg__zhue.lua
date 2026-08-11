local s = fk.CreateSkill { name = "fengsui_heg__zhue" }
s:addEffect(fk.CardUsing, {
  global = true,
  can_trigger = function(self, event, target, player, data) return target ~= player and player:hasSkill(s.name) and player:getMark(s.name.."-round")==0 and data.card.type~=Card.TypeEquip and target.kingdom==player.kingdom end,
  on_cost = function(self,event,target,player,data) return player.room:askToSkillInvoke(player,{skill_name=s.name}) end,
  on_use = function(self,event,target,player,data) player.room:setPlayerMark(player,s.name.."-round",1); target:drawCards(1,s.name); data.disresponsiveList=table.simpleClone(player.room.players) end,
})
return s
