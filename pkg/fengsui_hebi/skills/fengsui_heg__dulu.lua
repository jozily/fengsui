local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local dufa = fk.CreateSkill { name = "fengsui_heg__dulu" }
dufa:addEffect(fk.DamageCaused, { can_trigger = function(self, _, target, player, data) return target == player and player:hasSkill(self.name) and data and data.to and data.damage and data.to.general ~= "anjiang" and data.to.deputyGeneral ~= "anjiang" and H.getGeneralsRevealedNum(player) ~= H.getGeneralsRevealedNum(data.to) end,
    on_use = function(self, _, _, player, data)
      local room=data.to.room; local choice=room:askToChoice(data.to,{choices={"fengsui_heg__dulu_discard","fengsui_heg__dulu_draw"},skill_name=self.name})
      if choice=="fengsui_heg__dulu_discard" then
        local choices={}
        if #data.to:getCardIds("h")>0 then table.insert(choices,"fengsui_heg__dulu_hand") end
        if #data.to:getCardIds("e")>0 then table.insert(choices,"fengsui_heg__dulu_equip") end
        if #choices==0 then return end
        local zone=room:askToChoice(data.to,{choices=choices,skill_name=self.name})
        local ids=zone=="fengsui_heg__dulu_hand" and data.to:getCardIds("h") or data.to:getCardIds("e")
        room:askToDiscard(data.to,{min_num=#ids,max_num=#ids,include_equip=zone=="fengsui_heg__dulu_equip",skill_name=self.name}); data.damage=0
      else room:drawCards(player,1,self.name) end
    end })

return dufa
