local huaixiang = fk.CreateSkill{
  name = "fengsui_heg__huaixiangRemake",
}

local discarded_types_mark = "fengsui_heg__huaixiangRemake_discarded_types-turn"

huaixiang:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player.room.current == player and table.find(data, function(move)
      return move.toArea == Card.DiscardPile and #move.moveInfo > 0
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local types = player:getTableMark(discarded_types_mark)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(types, Fk:getCardById(info.cardId).type)
        end
      end
    end
    player.room:setPlayerMark(player, discarded_types_mark, types)
  end,
})

huaixiang:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__huaixiangRemake-active",
  card_num = 1,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    return not table.contains(player:getTableMark(discarded_types_mark), Fk:getCardById(to_select).type)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.kingdom ~= "unknown"
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, effect.from, huaixiang.name)
    room:addPlayerMark(effect.tos[1], "fengsui_heg__huaixiangRemake_unknown-turn", 1)
    room:setPlayerProperty(effect.tos[1], "kingdom", "unknown")
  end,
})

huaixiang:addEffect(fk.EventPhaseStart, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("fengsui_heg__huaixiangRemake_unknown-turn") > 0 then
        room:setPlayerMark(p, "fengsui_heg__huaixiangRemake_unknown-turn", 0)
        local kingdom = p:getMark("__heg_kingdom")
        if kingdom == "wild" then kingdom = p:getMark("__heg_init_kingdom") end
        room:setPlayerProperty(p, "kingdom", kingdom)
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__huaixiangRemake"] = "怀香·旧",
  [":fengsui_heg__huaixiangRemake"] = "出牌阶段，你可以重铸一张本回合未进入弃牌堆类别的牌并选择一名确定势力的角色，其本回合视为未确定势力。",
  ["#fengsui_heg__huaixiangRemake-active"] = "怀香·旧：重铸一张合规手牌，令一名确定势力的角色暂时变为未确定势力",
}

return huaixiang
