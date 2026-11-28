-- 怀香的一次性选择窗：同一界面里选一张弃牌堆牌 + 一名目标角色。
-- 牌由 extra_data.cards 传入（expand_pile 展开到弃牌堆实体牌），
-- 目标限定为其他确定势力角色。
local huaixiang_active = fk.CreateSkill {
  name = "#fengsui_heg__huaixiang_active",
}

Fk:loadTranslationTable {
  ["#fengsui_heg__huaixiang_active"] = "怀香",
  ["#fengsui_heg__huaixiang-active"] = "请选择一张要获得的牌和一名本回合视为未确定势力的其他角色",
}

huaixiang_active:addEffect("active", {
  card_num = 1,
  target_num = 1,
  expand_pile = function(self, player)
    return self.cards
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(self.cards, to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and to_select.kingdom ~= "unknown"
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected_cards == 1 and #selected == 1
  end,
})

return huaixiang_active
