local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local qusheng = fk.CreateSkill { name = "fengsui_heg__qushengRemake" }

-- 旧版取声：每回合限一次，获得弃牌堆中唯一一张同名异花色的牌。
local function findUniqueMatch(room, id)
  local card = Fk:getCardById(id)
  if not card then return nil end
  local match, found = nil, 0
  for _, other in ipairs(room.discard_pile) do
    if other ~= id then
      local c = Fk:getCardById(other)
      if c and c.name == card.name and c.suit ~= card.suit then
        found = found + 1
        match = other
        if found > 1 then return nil end
      end
    end
  end
  return found == 1 and match or nil
end

qusheng:addEffect(fk.AfterCardsMove, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    if not U.hasGeneralName(player, "fengsui_heg__biyu") then return false end
    if player:getMark(self.name .. "-turn") > 0 then return false end
    if not data then return false end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveInfo then
        for _, info in ipairs(move.moveInfo) do
          if findUniqueMatch(player.room, info.cardId) then return true end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local candidates = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveInfo then
        for _, info in ipairs(move.moveInfo) do
          local m = findUniqueMatch(player.room, info.cardId)
          if m then table.insert(candidates, { orig = info.cardId, match = m }) end
        end
      end
    end
    if #candidates == 0 then return false end
    if player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__qushengRemake-invoke" }) then
      event:setCostData(self, { candidates = candidates })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name .. "-turn", 1)
    for _, pair in ipairs(event:getCostData(self).candidates) do
      local gain, put = pair.match, pair.orig
      room:obtainCard(player, gain, true, fk.ReasonPrey, player, self.name)
      if room:getCardArea(put) == Card.DiscardPile then
        room:moveCards {
          ids = { put }, toArea = Card.DrawPile, drawPilePosition = 1,
          moveReason = fk.ReasonPut, skillName = self.name, moveVisible = true,
        }
      end
    end
  end,
})

qusheng:addEffect(fk.TurnStart, { global = true,
  can_refresh = function(self, _, target) return target ~= nil end,
  on_refresh = function(self, _, target) target.room:setPlayerMark(target, self.name .. "-turn", 0) end,
})

return qusheng
