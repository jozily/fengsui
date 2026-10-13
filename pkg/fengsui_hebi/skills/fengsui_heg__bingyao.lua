local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local bingyao = fk.CreateSkill { name = "fengsui_heg__bingyao" }
bingyao:addEffect(fk.TargetSpecified,{can_trigger=function(self,_,target,player,data) return player:hasSkill(self.name) and U.getSkillPlace(player,self.name)==false and data and data.from and data.from~=player and data.card and #data.use.tos==1 and table.find(data.use.tos,function(x) return H.compareKingdomWith(player,x) and not H.compareKingdomWith(player,data.from) end)~=nil end,on_use=function(self,_,_,player,data) local room=player.room;
local victim=table.find(data.use.tos,function(x) return H.compareKingdomWith(player,x) end);
if not victim or not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__bingyao-invoke::"..victim.id}
) then return end;
U.swapGenerals(room,player);
data:cancelTarget(victim);
room:addPlayerMark(victim,"fengsui_heg__bingyao_target",1);
room:drawCards(victim,1,self.name) end}
)
bingyao:addEffect(fk.TargetSpecified,{can_trigger=function(self,_,target,player,data) return player:hasSkill(self.name) and U.getSkillPlace(player,self.name)==true and data and data.from and H.compareKingdomWith(player,data.from) and data.card and #data.use.tos==1 and not H.compareKingdomWith(player,data.use.tos[1]) end,on_use=function(self,_,_,player,data) local room=player.room;
local candidates=table.filter(room.alive_players,function(x) return H.compareKingdomWith(player,x) and not table.contains(data.use.tos,x) and data.from:canUseTo(data.card,x,{bypass_distances=true}
) end);
if #candidates==0 or not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__bingyao-add"}
) then return end;
U.swapGenerals(room,player);
data:addTarget(candidates[1]);
room:addPlayerMark(data.from,"fengsui_heg__bingyao_target",1);
room:drawCards(data.from,1,self.name) end}
)
return bingyao
