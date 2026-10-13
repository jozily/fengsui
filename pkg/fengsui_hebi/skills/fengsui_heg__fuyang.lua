local H = require "packages.fengsui.hegemony_util"
local fuyang = fk.CreateSkill { name = "fengsui_heg__fuyang", tags = { Skill.Compulsory } }
fuyang:addEffect(fk.GeneralRevealed,{can_trigger=function(self,_,target,player) return target==player and player:hasShownSkill(self.name) and player:getMark("fengsui_heg__fuyang_used")==0 end,on_use=function(self,_,_,player) local room=player.room;
room:setPlayerMark(player,"fengsui_heg__fuyang_used",1);
H.addHegMark(player,"fengsui_heg_ascend");
H.addHegMark(player,"fengsui_heg__descend") end}
)
return fuyang
