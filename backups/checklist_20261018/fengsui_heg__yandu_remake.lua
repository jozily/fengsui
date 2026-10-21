local yandu = fk.CreateSkill { name = "fengsui_heg__yandu" }

yandu:addEffect(fk.GeneralShown, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(self.name) and #player:getCardIds("he") > 0
  end,
  on_use = function(self, _, _, player)
    local room, used = player.room, {}
    while not player:isNude() do
      local available = {}
      for _, id in ipairs(player:getCardIds("he")) do
        local typ = Fk:getCardById(id).type
        if not table.contains(used, typ) then table.insertIfNeed(available, typ) end
      end
      if #available == 0 then break end
      local choices = table.map(available, function(t) return "fengsui_heg__yandu_type_" .. tostring(t) end)
      table.insert(choices, "Cancel")
      local choice = room:askToChoice(player, { choices = choices, skill_name = self.name, prompt = "#fengsui_heg__yandu-choice" })
      if choice == "Cancel" then break end
      local typ = tonumber(choice:match("_(%d+)$"))
      local cards = table.filter(player:getCardIds("he"), function(id) return Fk:getCardById(id).type == typ end)
      if #cards == 0 then break end
      local selected = room:askToCards(player, { min_num = 1, max_num = 1, include_equip = true, skill_name = self.name, pattern = tostring(Exppattern { id = cards }), prompt = "#fengsui_heg__yandu-card", cancelable = true })
      if #selected == 0 then break end
      table.insert(used, typ)
      room:recastCard(selected, player, self.name)
    end
  end,
})

return yandu
