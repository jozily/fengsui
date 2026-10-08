local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local xiangchen=fk.CreateSkill{name="fengsui_heg__xiangchen"}
xiangchen:addEffect(fk.HpChanged,{global=true,can_trigger=function(self,_,target,player) return target and target~=player and player:hasSkill(self.name) and H.compareKingdomWith(player,target) and player.room.current and player.room.current.kingdom~="unknown" and #player.room.general_pile>0 end,on_use=function(self,_,target,player)
    local room=player.room; local pool=table.filter(room.general_pile,function(n) local g=Fk.generals[n]; return g and g.kingdom==target.kingdom and g.maxHp==target.maxHp end)
    if #pool==0 then return end
    -- X 是当前回合角色所属势力的角色数，而不是势力种类数。
    local n=0; for _,p in ipairs(room.alive_players) do if p.kingdom==room.current.kingdom then n=n+1 end end; n=math.max(1, math.min(#pool,n)); local choices={}
    for i=1,n do local g=table.remove(pool,math.random(#pool)); table.insert(choices,g); table.removeOne(room.general_pile,g) end
    local gname=room:askToChooseGeneral(player,{generals=choices,skill_name=self.name,prompt="#fengsui_heg__xiangchen-choose"})
    if not gname then gname=choices[1] end
    -- “谶”只记录置于目标武将牌上的武将，不在触发时直接获得技能。
    room:setPlayerMark(target,"fengsui_heg__xiangchen_general",gname)
    room:setPlayerMark(target,"fengsui_heg__xiangchen_skill",0)
    room:setPlayerMark(target,"fengsui_heg__xiangchen_wait",1)
    if target.general ~= "anjiang" and target.deputyGeneral ~= "anjiang" then room:setPlayerMark(target,"fengsui_heg__xiangchen_ready",1) end
    room:addPlayerMark(target,"fengsui_heg__xiangchen_mark",1)
  end})
  xiangchen:addEffect(fk.GeneralHidden,{global=true,can_trigger=function(self,_,target,player)
    return target==player and player:getMark("fengsui_heg__xiangchen_general")~=0 and player:getMark("fengsui_heg__xiangchen_ready")==1 and player:hasSkill(self.name)
  end,on_use=function(self,_,_,player)
    local room=player.room; local gname=player:getMark("fengsui_heg__xiangchen_general"); local g=Fk.generals[gname]; if not g then return end
    local choices=table.filter(g:getSkillNameList(),function(x) local z=Fk.skills[x]; return z and not z:hasTag(Skill.Lord) end)
    if #choices>0 then
      local sk=room:askToChoice(player,{choices=choices,skill_name=self.name,prompt="#fengsui_heg__xiangchen-skill"})
      if sk then room:handleAddLoseSkills(player,sk); room:setPlayerMark(player,"fengsui_heg__xiangchen_skill",sk); room:addTableMark(player,"fengsui_heg__xiangchen_skills",sk) end
    end
    room:setPlayerMark(player,"fengsui_heg__xiangchen_ready",0)
  end})
  xiangchen:addEffect(fk.TurnStart,{global=true,can_trigger=function(self,_,target,player) return target and target:getMark("fengsui_heg__xiangchen_general")~=0 and target:getMark("fengsui_heg__xiangchen_wait")==1 end,on_use=function(self,_,target,player) target.room:setPlayerMark(target,"fengsui_heg__xiangchen_wait",2) end})
  xiangchen:addEffect(fk.TurnEnd,{global=true,can_trigger=function(self,_,target,player) return target and target:getMark("fengsui_heg__xiangchen_general")~=0 and target:getMark("fengsui_heg__xiangchen_wait")==2 end,on_use=function(self,_,target,player)
    local room=target.room; local count=target:getMark("fengsui_heg__xiangchen_mark"); local g=target:getMark("fengsui_heg__xiangchen_general")
    if type(g)=="string" and g~="" then table.insert(room.general_pile,g) end
    if type(target:getMark("fengsui_heg__xiangchen_skill"))=="string" and target:getMark("fengsui_heg__xiangchen_skill")~="" then room:handleAddLoseSkills(target,"-"..target:getMark("fengsui_heg__xiangchen_skill")) end
    target:setMark("fengsui_heg__xiangchen_general",0); target:setMark("fengsui_heg__xiangchen_skill",0); target:setMark("fengsui_heg__xiangchen_mark",0); target:setMark("fengsui_heg__xiangchen_wait",0); target:setMark("fengsui_heg__xiangchen_ready",0)
    if count>0 then room:drawCards(target,count,self.name) end
  end})

return xiangchen
