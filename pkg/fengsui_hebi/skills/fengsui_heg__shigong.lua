local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local shigong=fk.CreateSkill{name="fengsui_heg__shigong",tags={Skill.Limited}}
shigong:addEffect(fk.EnterDying,{can_trigger=function(self,_,target,player) return target==player and player:hasSkill(self.name) and player.room.current~=player and player:getMark("fengsui_heg__shigong_used")==0 and player.deputyGeneral~="anjiang" end,on_use=function(self,_,_,player)
    local room=player.room; room:setPlayerMark(player,"fengsui_heg__shigong_used",1)
    local old=player.deputyGeneral; local oldskills={}
    if Fk.generals[old] then oldskills=table.filter(Fk.generals[old]:getSkillNameList(),function(x) local z=Fk.skills[x]; return z and not z:hasTag(Skill.Lord) and not z:hasTag(Skill.Limited) end) end
    require("packages.fengsui.pkg.fengsui_hebi.util").removeGeneral(player,true)
    local cur=room.current; if not cur then return end
    local c=room:askToChoice(cur,{choices={"fengsui_heg__shigong_gain","fengsui_heg__shigong_full"},skill_name=self.name})
    if c=="fengsui_heg__shigong_gain" then
      if #oldskills>0 then
        local sk=room:askToChoice(cur,{choices=oldskills,skill_name=self.name,prompt="#fengsui_heg__shigong-skill"})
        if sk then room:handleAddLoseSkills(cur,sk) end
      end
      room:drawCards(cur,cur.maxHp,self.name); room:recover{who=player,num=1,recoverBy=player,skillName=self.name}
    else
      local n=player.maxHp-player.hp; if n>0 then room:recover{who=player,num=n,recoverBy=player,skillName=self.name} end
    end
  end})
return shigong
