local H = require "packages.fengsui.hegemony_util"
_G.__fengsui_heg_daoli_skills=_G.__fengsui_heg_daoli_skills or {}
local function collectSkills(target)
  local result = {}
  for _, name in ipairs({target.general, target.deputyGeneral}) do
    local g = name and Fk.generals[name]
    if g then for _, sk in ipairs(g:getSkillNameList(true)) do local obj=Fk.skills[sk]; if obj and not obj:hasTag(Skill.Lord) and not obj:hasTag(Skill.Limited) and not obj:hasTag(Skill.Compulsory) and not table.contains(result,sk) then table.insert(result,sk) end end end
  end
  return result
end
local daoli_on_death = fk.CreateSkill { name = "fengsui_heg__daoli_on_death" }
daoli_on_death:addEffect(fk.Death,{global=true,can_trigger=function(self,_,target,player) return target==player and player:hasSkill("fengsui_heg__daoli") end,on_use=function(self,_,_,player) local room=player.room; local candidates=table.filter(room.alive_players,function(x) return x~=player and H.compareKingdomWith(player,x) end); if #candidates==0 then return end; local tos=room:askToChoosePlayers(player,{targets=candidates,min_num=1,max_num=1,skill_name="fengsui_heg__daoli",prompt="#fengsui_heg__daoli-clean",cancelable=false}); local receiver=tos[1]; if not receiver then return end; local ids=player:getCardIds("hej"); if #ids>0 then room:obtainCard(receiver,ids,true,fk.ReasonPrey,player,"fengsui_heg__daoli"); _G.__fengsui_heg_daoli_stolen[receiver.id]=ids end; local skills=collectSkills(player); if #skills>0 then room:handleAddLoseSkills(receiver,table.concat(skills,",")); _G.__fengsui_heg_daoli_skills[receiver.id]=skills end; room:setPlayerMark(receiver,"fengsui_heg__daoli_extra",1) end})
return daoli_on_death
