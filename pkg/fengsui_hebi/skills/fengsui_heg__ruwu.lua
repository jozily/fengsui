local ruwu = fk.CreateSkill {
  name = "fengsui_heg__ruwu",
}

-- 国战标记：先驱 / 阴阳鱼 / 珠联璧合 / 野心家
local HEG_MARKS = { "@!!vanguard", "@!!yinyangfish", "@!!companion", "@!!wild" }

local function hasHegMark(p)
  for _, mark in ipairs(HEG_MARKS) do
    if p:getMark(mark) > 0 then return true end
  end
  return false
end

local function hasPileChange(data)
  if not data then return false end
  return table.find(data, function(move)
    -- 牌堆牌数量增加：有牌进入牌堆
    if move.toArea == Card.DrawPile then return true end
    -- 弃牌堆牌数量减少：有牌从弃牌堆离开（逐张判断 moveInfo.fromArea）
    if move.moveInfo then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.DiscardPile then return true end
      end
    end
    return false
  end) ~= nil
end

ruwu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, _, _, player, data)
    if not (player:isAlive() and player:hasShownSkill(self.name) and hasPileChange(data)) then
      return false
    end
    return table.find(player.room.alive_players, hasHegMark) ~= nil
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local targets = table.filter(room.alive_players, hasHegMark)
    if #targets == 0 then return end
    local chosen = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = self.name,
      prompt = "#fengsui_heg__ruwu-target",
      cancelable = false,
    })
    if #chosen == 0 then return end
    local to = chosen[1]
    if not to:isAlive() then return end
    -- 有珠联璧合标记则摸两张，否则摸一张
    local n = to:getMark("@!!companion") > 0 and 2 or 1
    room:drawCards(to, n, self.name)
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__ruwu-target"] = "如晤：选择一名有国战标记的角色摸牌",
}

return ruwu
