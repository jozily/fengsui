local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local qiju = fk.CreateSkill { name = "fengsui_heg__qiju", tags = { Skill.Limited } }
local function getOwner(room)
  return table.find(room.alive_players, function(p)
    return p:hasShownSkill(qiju.name) and p:getMark("fengsui_heg__qiju_used") > 0
  end)
end
qiju:addEffect("active", {card_num=0,target_num=0,can_use=function(self,p) return p:hasShownSkill(self.name) and p:getMark("fengsui_heg__qiju_used")==0 end,card_filter=Util.FalseFunc,target_filter=Util.FalseFunc,on_use=function(self,room,effect)
 local p=effect.from;

room:setPlayerMark(p,"fengsui_heg__qiju_used",1);

local n=H.getGeneralsRevealedNum(p);

for _,x in ipairs(room.alive_players) do if x~=p and H.getGeneralsRevealedNum(x)~=n then room:changeKingdom(x,"unknown",true) end end
end}
)
qiju:addEffect("targetmod", {
  global = true,
  mod_target_filter = function(self, player, to_select, selected, card)
    local owner = getOwner(player.room)
    return owner and H.getGeneralsRevealedNum(player) == H.getGeneralsRevealedNum(owner) and
      player:getMark("fengsui_heg__qiju-turn") == 0 and card and (card.name == "slash" or card.trueName == "slash") and
      to_select.kingdom == "unknown"
  end,
})
qiju:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local owner = getOwner(player.room)
    return owner and target == player and H.getGeneralsRevealedNum(player) == H.getGeneralsRevealedNum(owner) and
      player:getMark("fengsui_heg__qiju-turn") == 0 and data and data.card and (data.card.name == "slash" or data.card.trueName == "slash") and
      table.find(data.tos or {}, function(p) return p.kingdom == "unknown" end) ~= nil
  end,
  on_use = function(self, _, _, player)
    player.room:setPlayerMark(player, "fengsui_heg__qiju-turn", 1)
  end,
})
return qiju

