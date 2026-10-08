local s=fk.CreateSkill{name="fengsui_heg__shenyu_track"}
s:addEffect(fk.AfterCardsMove,{global=true,on_use=function(self,_,target,player,data) local c=player.room.current; if not c or not data then return end; local n=0; for _,m in ipairs(data) do if m.from==c and m.moveReason==fk.ReasonDiscard and m.toArea==Card.DiscardPile then n=n+#m.moveInfo end end; if n>0 then player.room:addPlayerMark(c,"fengsui_heg__shenyu-discard",n) end end})
return s
