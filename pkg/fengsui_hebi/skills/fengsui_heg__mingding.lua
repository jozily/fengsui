local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local mingding=fk.CreateSkill{name="fengsui_heg__mingding",tags={Skill.Limited}}
mingding:addEffect(fk.EnterDying,{can_trigger=function(self,_,target,player) return target~=player and player:hasSkill(self.name) and player:getMark("fengsui_heg__mingding_used")==0 and H.compareKingdomWith(player,target) and target:getMark("fengsui_heg__xiangchen_mark")>0 end,on_use=function(self,_,target,player) local room=player.room;room:setPlayerMark(player,"fengsui_heg__mingding_used",1);room:recover{who=target,num=1,recoverBy=player,skillName=self.name};local pool=target:getMark("fengsui_heg__xiangchen_skills"); if type(pool)=="table" and #pool>0 then local sk=pool[math.random(#pool)]; if sk and Fk.skills[sk] then room:handleAddLoseSkills(target,sk) end end;if player.deputyGeneral~="anjiang" then require("packages.fengsui.pkg.fengsui_hebi.util").removeGeneral(player,true) end;if target.deputyGeneral~="anjiang" then require("packages.fengsui.pkg.fengsui_hebi.util").removeGeneral(target,true) end end})

return mingding
