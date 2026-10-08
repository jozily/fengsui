_G.__fengsui_heg_daoli_stolen=_G.__fengsui_heg_daoli_stolen or {}
_G.__fengsui_heg_daoli_skills=_G.__fengsui_heg_daoli_skills or {}
local s=fk.CreateSkill{name="fengsui_heg__daoli_extra"}
s:addEffect(fk.TurnEnd,{global=true,on_use=function(self,_,target) local r=target.room; for _,p in ipairs(r.alive_players) do if p:getMark("fengsui_heg__daoli_extra")>0 then r:setPlayerMark(p,"fengsui_heg__daoli_extra",0); if p:isAlive() then p:gainAnExtraPhase(Player.Play,"fengsui_heg__daoli") end; local stolen=_G.__fengsui_heg_daoli_stolen[p.id]; if stolen then local present=table.filter(stolen,function(id) return table.contains(p:getCardIds("hej"),id) end); if #present>0 then r:throwCard(present,"fengsui_heg__daoli",p,p) end; _G.__fengsui_heg_daoli_stolen[p.id]=nil end; local skills=_G.__fengsui_heg_daoli_skills[p.id]; if skills then r:handleAddLoseSkills(p,"-"..table.concat(skills,",-")); _G.__fengsui_heg_daoli_skills[p.id]=nil end end end end})
return s
