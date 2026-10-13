local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local jiaosu = fk.CreateSkill { name = "fengsui_heg__jiaosu", tags = { Skill.MainPlace } }
 jiaosu:addEffect(fk.TargetSpecified, { can_trigger = function(self, _, target, player, data) return player:hasShownSkill(self.name) and U.getSkillPlace(player, self.name) == false and data and data.from and data.from ~= player and not H.compareKingdomWith(player, data.from) and data.card and data.to and H.compareKingdomWith(player, data.to) and (not data.use or #data.use.tos == 1) end, on_use = function(self, _, _, player, data) local room=player.room;
local victim=data.to;
if not victim or not room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__jiaosu-invoke::"..victim.id}
) then return end;
room:addPlayerMark(player,"fengsui_heg__chuguang_count-round",1);
U.swapGenerals(room,player);
data:cancelTarget(victim);
room:addPlayerMark(victim,"fengsui_heg__jiaosu_target",1);
room:addTableMark(player,"@fengsui_heg__jiaosu_count-round",Fk:translate(H.getActualGeneral(victim, false)));
room:addTableMark(victim,"@fengsui_heg__jiaosu_target",Fk:translate(H.getActualGeneral(player, false)));
room:drawCards(victim,1,self.name) end }
)
jiaosu:addEffect(fk.AfterDying,{global=true,can_trigger=function(self,_,target,player) return target and player:hasShownSkill(self.name) and U.getSkillPlace(player,self.name)==false and H.compareKingdomWith(player,target) and target:getMark("fengsui_heg__jiaosu_target")>0 end,on_use=function(self,_,target,player) local room=player.room;
room:setPlayerMark(target,"fengsui_heg__jiaosu_target",0);
room:setPlayerMark(target,"@fengsui_heg__jiaosu_target",0);
room:setPlayerMark(target,"fengsui_heg__jiaosu_extra-turn",1) end}
)
jiaosu:addEffect(fk.TurnEnd,{global=true,can_trigger=function(self,_,target) return target and target:isAlive() and target:getMark("fengsui_heg__jiaosu_extra-turn")>0 end,on_use=function(self,_,target) local room=target.room;
room:setPlayerMark(target,"fengsui_heg__jiaosu_extra-turn",0);
if target.general=="anjiang" then target:revealGeneral(false) end;
if target.deputyGeneral=="anjiang" then target:revealGeneral(true) end;
target:gainAnExtraPhase(Player.Play,self.name) end}
)
return jiaosu
