local H = require "packages.fengsui.hegemony_util"

local huaixiang = fk.CreateSkill {
  name = "fengsui_heg__huaixiang",
}

local original_kingdom_mark = "fengsui_heg__huaixiang_original_kingdom-turn"
local category_mark = "@fengsui_heg__huaixiang_category-turn"

local function categoryText(card)
  if card.type == Card.TypeBasic then return "基"
  elseif card.type == Card.TypeTrick then return "锦"
  elseif card.type == Card.TypeEquip then return "装" end
end

local function entersDiscard(move)
  return move.toArea == Card.DiscardPile and #move.moveInfo > 0 and
    move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResponse
end

local function getEligibleCards(room, player, data)
  local used = player:getMark(category_mark)
  if type(used) ~= "string" then used = "" end
  local ids = {}
  for _, move in ipairs(data) do
    if entersDiscard(move) then
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        local card = Fk:getCardById(id)
        local category = categoryText(card)
        if category and not used:find(category, 1, true) and room:getCardArea(id) == Card.DiscardPile then
          table.insertIfNeed(ids, id)
        end
      end
    end
  end
  return ids
end

huaixiang:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
    return player:hasSkill(self.name) and current and current.phase ~= Player.NotActive and
      (current == player or (current.kingdom ~= "unknown" and player.kingdom ~= "unknown" and
        H.compareKingdomWith(current, player))) and #getEligibleCards(room, player, data) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = getEligibleCards(room, player, data)
    if #ids == 0 then return false end
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = self.name,
      pattern = tostring(Exppattern { id = ids }),
      prompt = "#fengsui_heg__huaixiang-card",
      expand_pile = ids,
      cancelable = true,
    })
    if #cards == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = table.filter(room.alive_players, function(p) return p.kingdom ~= "unknown" end),
      skill_name = self.name,
      prompt = "#fengsui_heg__huaixiang-target",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { cards = cards, tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local id = cost.cards[1]
    local to = cost.tos[1]
    if room:getCardArea(id) ~= Card.DiscardPile then return end
    local card = Fk:getCardById(id)
    local category = categoryText(card)
    if not category then return end
    local used = player:getMark(category_mark)
    if type(used) ~= "string" then used = "" end
    if used:find(category, 1, true) then return end
    room:obtainCard(player, id, true, fk.ReasonPrey, player, self.name)
    room:setPlayerMark(player, category_mark, used .. category)
    if to:isAlive() and to.kingdom ~= "unknown" then
      room:setPlayerMark(to, original_kingdom_mark, to.kingdom)
      room:setPlayerMark(to, "@fengsui_heg__huaixiang-turn", "")
      room:setPlayerProperty(to, "kingdom", "unknown")
    end
  end,
})

huaixiang:addEffect(fk.TurnEnd, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return table.find(player.room.players, function(p)
      return p:getMark(original_kingdom_mark) ~= 0
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      local kingdom = p:getMark(original_kingdom_mark)
      if kingdom ~= 0 then
        room:setPlayerProperty(p, "kingdom", kingdom)
        room:setPlayerMark(p, original_kingdom_mark, 0)
        room:setPlayerMark(p, "@fengsui_heg__huaixiang-turn", 0)
      end
      room:setPlayerMark(p, category_mark, 0)
    end
  end,
})

return huaixiang
