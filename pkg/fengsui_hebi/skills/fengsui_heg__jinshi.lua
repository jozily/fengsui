local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local jinshi = fk.CreateSkill { name = "fengsui_heg__jinshi", tags = { Skill.Compulsory } }
local readyMark = "fengsui_heg__jinshi_ready"
local function punish(self, player)
  local place = U.getSkillPlace(player, self.name)
  if place == nil then return end
  if place == false and player.deputyGeneral == "anjiang" then return end
  if place == true and player.general == "anjiang" then return end
  player:hideGeneral(place)
  player.room:loseHp(player, 1)
  -- 只有因另一张武将牌变化而被暗置后，下一次明置才结算噤誓。
  player.room:setPlayerMark(player, readyMark, 1)
end
jinshi:addEffect(fk.GeneralShown,{global=true,can_trigger=function(self,_,target,player,data) return target==player and player:hasShownSkill(self.name) and data and ((U.getSkillPlace(player,self.name)==false and data.d) or (U.getSkillPlace(player,self.name)==true and data.m)) and player.general~="anjiang" and player.deputyGeneral~="anjiang" end,on_use=function(self,_,target,player) punish(self,player) end})
jinshi:addEffect(fk.GeneralRevealed,{can_trigger=function(self,_,target,player,data)
  local place = U.getSkillPlace(player, self.name)
  return target==player and player:hasShownSkill(self.name) and player:getMark(readyMark)>0 and data and
    ((place==false and data.m) or (place==true and data.d))
end,on_use=function(self,_,_,player)
  local room = player.room
  room:setPlayerMark(player,readyMark,0)
  local n=player:getMaxCards()-player:getHandcardNum()
  if n>0 then room:drawCards(player,n,self.name) end
  if #player:getCardIds("he") > 0 then
    room:askToUseCard(player, { skill_name = self.name, prompt = "#fengsui_heg__jinshi-use", cancelable = true })
  end
end})
jinshi:addEffect(H.GeneralTransformed,{global=true,can_trigger=function(self,_,target,player,data)
  local place=U.getSkillPlace(player,self.name)
  return target==player and player:hasShownSkill(self.name) and place~=nil and data and data.isMain==place and
    player.general~="anjiang" and player.deputyGeneral~="anjiang"
end,on_use=function(self,_,_,player) punish(self,player) end})
jinshi:addEffect(H.GeneralRemoved,{global=true,can_trigger=function(self,_,target,player,data)
  local place=U.getSkillPlace(player,self.name)
  return target==player and player:hasShownSkill(self.name) and place~=nil and data and data.isDeputy~=place
end,on_use=function(self,_,_,player) punish(self,player) end})
return jinshi
