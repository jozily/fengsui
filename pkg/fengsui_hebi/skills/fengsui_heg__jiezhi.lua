local jiezhi = fk.CreateSkill {
  name = "fengsui_heg__jiezhi",
  tags = { Skill.Compulsory },
}
local H = require "packages.fengsui.hegemony_util"

local function displayRole(player)
  local shown = {}
  if player.general ~= "anjiang" then
    local general = H.getActualGeneral(player, false)
    if general then table.insert(shown, Fk:translate(general)) end
  end
  if player.deputyGeneral ~= "anjiang" then
    local general = H.getActualGeneral(player, true)
    if general then table.insert(shown, Fk:translate(general)) end
  end
  if #shown == 0 then return "座次" .. tostring(player.seat) .. "号位" end
  return table.concat(shown, " ")
end

local function gainedCards(player, data)
  local result = {}
  for _, move in ipairs(data or {}) do
    if move.from == player and move.to and move.to ~= player and
        move.toArea == Card.PlayerHand then
      for _, info in ipairs(move.moveInfo or {}) do
        table.insert(result, { to = move.to, id = info.cardId })
      end
    end
  end
  return result
end

local function matchingDiscard(room, card_id)
  local card = Fk:getCardById(card_id, true)
  if not card then return nil end
  local same_name = table.filter(room.discard_pile, function(id)
    local other = Fk:getCardById(id, true)
    return other and other.trueName == card.trueName
  end)
  return #same_name == 1 and same_name[1] or nil
end

-- 其他角色获得节枝持有者的牌后，先展示这些牌，再检查后半段效果。
jiezhi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, _, _, player, data)
    if not player:hasSkill(self.name, true, true) then return false end
    return #gainedCards(player, data) > 0
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    local gains = gainedCards(player, data)
    room:showCards(table.map(gains, function(gained) return gained.id end), player)
    for _, gained in ipairs(gains) do
      local discard_id = matchingDiscard(room, gained.id)
      if discard_id and room:getCardArea(discard_id) == Card.DiscardPile then
        room:obtainCard(player, discard_id, true, fk.ReasonPrey, player, self.name)
        room:addTableMarkIfNeed(gained.to, self.name .. "_prohibit-turn", player.id)
        room:addTableMarkIfNeed(player, self.name .. "_prohibit-turn", gained.to.id)
        room:addTableMarkIfNeed(gained.to, "@" .. self.name .. "-turn", displayRole(player))
        room:addTableMarkIfNeed(player, "@" .. self.name .. "-turn", displayRole(gained.to))
      end
    end
  end,
})

jiezhi:addEffect("prohibit", {
  global = true,
  is_prohibited = function(self, from, to, card)
    return from and to and table.contains(from:getTableMark(jiezhi.name .. "_prohibit-turn"), to.id)
  end,
})

return jiezhi
