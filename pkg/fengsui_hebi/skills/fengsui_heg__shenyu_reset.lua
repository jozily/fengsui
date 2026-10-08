local s=fk.CreateSkill{name="fengsui_heg__shenyu_reset"}
s:addEffect(fk.TurnStart,{global=true,on_use=function(self,_,target) local r=target.room; r:setPlayerMark(target,"fengsui_heg__shenyu-turn",0); r:setPlayerMark(target,"fengsui_heg__shenyu-discard",0); r:setPlayerMark(target,"fengsui_heg__qiju-turn",0); r:setPlayerMark(target,"fengsui_heg__quchi_empty-turn",0) end})
return s
