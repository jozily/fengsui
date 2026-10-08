local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local jinshi = fk.CreateSkill { name = "fengsui_heg__jinshi", tags = { Skill.Compulsory } }
local function punish(self, player)
  local place = U.getSkillPlace(player, self.name)
  if place == nil then return end
  if place == false and player.deputyGeneral == "anjiang" then return end
  if place == true and player.general == "anjiang" then return end
  player:hideGeneral(place)
  player.room:loseHp(player, 1)
end
jinshi:addEffect(fk.GeneralShown,{global=true,can_trigger=function(self,_,target,player,data) return target==player and player:hasSkill(self.name) and data and ((U.getSkillPlace(player,self.name)==false and data.d) or (U.getSkillPlace(player,self.name)==true and data.m)) and player.general~="anjiang" and player.deputyGeneral~="anjiang" end,on_use=function(self,_,target,player) punish(self,player) end})
jinshi:addEffect(fk.GeneralRevealed,{can_trigger=function(self,_,target,player) return target==player and player:hasSkill(self.name) and player:getMark("fengsui_heg__jinshi_revealed")==0 end,on_use=function(self,_,_,player) player.room:setPlayerMark(player,"fengsui_heg__jinshi_revealed",1); local n=player:getMaxCards()-player:getHandcardNum(); if n>0 then player.room:drawCards(player,n,self.name) end end})
jinshi:addEffect(H.GeneralTransformed,{global=true,can_trigger=function(self,_,target,player) return target==player and player:hasSkill(self.name) and player.general~="anjiang" and player.deputyGeneral~="anjiang" end,on_use=function(self,_,_,player) punish(self,player) end})
jinshi:addEffect(H.GeneralRemoved,{global=true,can_trigger=function(self,_,target,player) local place=U.getSkillPlace(player,self.name); return target==player and player:hasSkill(self.name) and place~=nil and ((place==false and player.general~="anjiang") or (place==true and player.deputyGeneral~="anjiang")) end,on_use=function(self,_,_,player) punish(self,player) end})
return jinshi
