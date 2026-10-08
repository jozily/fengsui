local fuyang = fk.CreateSkill { name = "fengsui_heg__fuyang" }
fuyang:addEffect(fk.GeneralRevealed,{can_trigger=function(self,_,target,player) return target==player and player:hasSkill(self.name) and player:getMark("fengsui_heg__fuyang_used")==0 end,on_use=function(self,_,_,player) local room=player.room; room:setPlayerMark(player,"fengsui_heg__fuyang_used",1); room:addPlayerMark(player,"@!!fengsui_heg_ascend",1); room:addPlayerMark(player,"@!!fengsui_heg__descend",1); room:handleAddLoseSkills(player,"fengsui_heg_ascend_skill&,fengsui_heg__descend_skill&") end})
return fuyang
