local quchi_empty = fk.CreateSkill { name = "#fengsui_heg__quchi_empty", tags = { Skill.Compulsory }, mute = true }
quchi_empty:addEffect(fk.AfterCardsMove,{global=true,can_trigger=function(self,_,target,player,data)
  if not player:hasSkill("fengsui_heg__quchi", true, true) or player:getMark("fengsui_heg__quchi_empty-turn")~=0 or not data then return false end
  return table.find(data,function(m)
    if m.from ~= player or not m.moveInfo then return false end
    for _, info in ipairs(m.moveInfo) do
      if (info.fromArea == Card.PlayerHand and #player:getCardIds("h") == 0) or
        (info.fromArea == Card.PlayerEquip and #player:getCardIds("e") == 0) or
        (info.fromArea == Card.PlayerJudge and #player:getCardIds("j") == 0) then
        return true
      end
    end
    return false
  end) ~= nil
end,on_use=function(self,_,_,player) player.room:setPlayerMark(player,"fengsui_heg__quchi_empty-turn",1);
local pile=player.room.draw_pile;
local id=pile[#pile];
if id then player.room:obtainCard(player,id,true,fk.ReasonPrey,player,self.name) end end}
)
return quchi_empty
