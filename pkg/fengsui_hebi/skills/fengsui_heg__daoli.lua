local H = require "packages.fengsui.hegemony_util"
_G.__fengsui_heg_daoli_stolen = _G.__fengsui_heg_daoli_stolen or {}
_G.__fengsui_heg_daoli_skills = _G.__fengsui_heg_daoli_skills or {}
local function collectSkills(target)
  local result = {}
  for _, name in ipairs({target.general, target.deputyGeneral}) do
    local g = name and Fk.generals[name]
    if g then
      for _, sk in ipairs(g:getSkillNameList(true)) do
        local obj = Fk.skills[sk]
        if obj and not obj:hasTag(Skill.Lord) and not obj:hasTag(Skill.Limited) and not obj:hasTag(Skill.Compulsory) and not table.contains(result, sk) then table.insert(result, sk) end
      end
    end
  end
  return result
end
local daoli = fk.CreateSkill { name = "fengsui_heg__daoli", tags = { Skill.Limited } }
daoli:addEffect(fk.Death,{global=true,can_trigger=function(self,_,target,player) return target and target~=player and player:hasSkill(self.name) and H.compareKingdomWith(player,target) and player:getMark("fengsui_heg__daoli_used")==0 end,on_cost=function(self,_,target,player) return player.room:askToSkillInvoke(player,{skill_name=self.name,prompt="#fengsui_heg__daoli-invoke"}) end,on_use=function(self,_,target,player) local room=player.room; room:setPlayerMark(player,"fengsui_heg__daoli_used",1); local ids=target:getCardIds("hej"); if #ids>0 then room:obtainCard(player,ids,true,fk.ReasonPrey,target,self.name); _G.__fengsui_heg_daoli_stolen[player.id]=ids end; local skills=collectSkills(target); if #skills>0 then room:handleAddLoseSkills(player,table.concat(skills,",")); _G.__fengsui_heg_daoli_skills[player.id]=skills end; room:setPlayerMark(player,"fengsui_heg__daoli_extra",1) end})
return daoli
