local H = require "packages.fengsui.hegemony_util"
local siji = fk.CreateSkill { name = "fengsui_heg__siji" }
siji:addEffect(fk.Damaged, {
    can_trigger = function(self, _, target, player) return target == player and player:hasSkill(self.name) and player.room.current end,
    on_cost = function(self, _, target, player) return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__siji-invoke" }) end,
    on_use = function(self, _, _, player)
      local room = player.room
      local current = room.current
      local choice = room:askToChoice(player, { choices = { "fengsui_heg__siji_up", "fengsui_heg__siji_down" }, skill_name = self.name })
      if choice == "fengsui_heg__siji_up" then
        if player:isNude() then return end
        room:askToDiscard(player, { min_num = 1, max_num = 1, include_equip = true, skill_name = self.name })
        room:addPlayerMark(current, MarkEnum.AddMaxCardsInTurn, 1)
      elseif current:getMaxCards() > 0 then
        room:drawCards(player, 1, self.name)
        room:addPlayerMark(current, MarkEnum.MinusMaxCardsInTurn, 1)
      end
      room:broadcastProperty(current, "MaxCards")
    end,
  })
  siji:addEffect(fk.Damage, {
    can_trigger = function(self, _, target, player, data) return player:hasSkill(self.name) and data and data.from == player and player.room.current ~= nil end,
    on_cost = function(self, _, target, player) return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__siji-invoke" }) end,
    on_use = function(self, _, _, player)
      local room=player.room; local current=room.current
      local choice=room:askToChoice(player,{choices={"fengsui_heg__siji_up","fengsui_heg__siji_down"},skill_name=self.name})
      if choice=="fengsui_heg__siji_up" then
        if player:isNude() then return end
        room:askToDiscard(player,{min_num=1,max_num=1,include_equip=true,skill_name=self.name})
        room:addPlayerMark(current,MarkEnum.AddMaxCardsInTurn,1)
      elseif current:getMaxCards()>0 then
        room:drawCards(player,1,self.name)
        room:addPlayerMark(current,MarkEnum.MinusMaxCardsInTurn,1)
      end
      room:broadcastProperty(current,"MaxCards")
    end,
  })
return siji
