local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local yaoming = fk.CreateSkill { name = "fengsui_heg__yaoming", tags = { Skill.DeputyPlace } }
yaoming:addEffect(fk.TargetSpecified,{can_trigger=function(self,_,target,player,data)
return player:hasShownSkill(self.name) and U.getSkillPlace(player,self.name)==true and data and data.from and H.compareKingdomWith(player,data.from) and data.card and data.to and not H.compareKingdomWith(player,data.to) and (not data.use or #data.use.tos==1)
end,on_use=function(self,_,_,player,data) local room=player.room;
local victim=data.to;
local candidates=table.filter(room.alive_players,function(p) return H.compareKingdomWith(player,p) and p~=victim and data.from:canUseTo(data.card,p)
end);
if #candidates==0 or not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__yaoming-add"}
) then return end;
room:addPlayerMark(player,"fengsui_heg__chuguang_count-round",1);
U.swapGenerals(room,player);
data:addTarget(candidates[1]);
room:addPlayerMark(data.from,"fengsui_heg__yaoming_target",1);
room:addTableMark(player,"@fengsui_heg__yaoming_count-round",tostring(data.from.seat));
room:addTableMark(data.from,"@fengsui_heg__yaoming_target",tostring(player.seat));
room:drawCards(data.from,1,self.name) end}
)
yaoming:addEffect(fk.Death,{global=true,can_trigger=function(self,_,target,player) return target and player:hasShownSkill(self.name) and H.compareKingdomWith(player,target) and target:getMark("fengsui_heg__yaoming_target")>0 end,on_use=function(self,_,target,player) local room=player.room;
room:setPlayerMark(target,"fengsui_heg__yaoming_target",0);
room:setPlayerMark(target,"@fengsui_heg__yaoming_target",0);
room:loseHp(player,1);
if player.deputyGeneral~="anjiang" then player:hideGeneral(true) end;
H.transformGeneral(room,player,false,false,1,self.name) end}
)
return yaoming
