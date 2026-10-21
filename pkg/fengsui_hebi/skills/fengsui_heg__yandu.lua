local yandu = fk.CreateSkill { name = "fengsui_heg__yandu" }

Fk:loadTranslationTable{
  ["fengsui_heg__yandu_type_1"] = "基本牌",
  ["fengsui_heg__yandu_type_2"] = "锦囊牌",
  ["fengsui_heg__yandu_type_3"] = "装备牌",
}

yandu:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player, data)
    local H = require "packages.fengsui.hegemony_util"
    local place = H.inGeneralSkills(player, self.name)
    return target == player and player:hasSkill(self.name) and data and
      ((place == "m" and data.m) or (place == "d" and data.d)) and #player:getCardIds("he") > 0
  end,
  on_use = function(self, _, _, player)
    local room, used = player.room, {}
    while player:isAlive() and not player:isNude() do
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
