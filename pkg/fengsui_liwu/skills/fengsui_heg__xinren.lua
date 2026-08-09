local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__xinren", tags = { Skill.Compulsory } }

local function damageCard(card)
  return card and card.is_damage_card
end

local function execute(player)
  local room = player.room
  local cards = player:getCardIds("h")
  local black = table.filter(cards, function(id)
    local card = Fk:getCardById(id)
    return card.color == Card.Black and damageCard(card)
  end)
  local aliveBefore = #room.alive_players
  if #cards > 0 then room:throwCard(cards, s.name, player, player) end

  for _, id in ipairs(black) do
    if player.dead then break end
    if room:getCardArea(id) == Card.DiscardPile then
      local use = room:askToUseRealCard(player, {
        pattern = tostring(Exppattern { id = { id } }),
        expand_pile = { id },
        skill_name = s.name,
        prompt = "#fengsui_heg__xinren-use::" .. Fk:getCardById(id):toLogString(),
        cancelable = false,
        skip = true,
        extra_data = { bypass_times = true, bypass_distances = true, extraUse = true },
      })
      if use then room:useCard(use) end
    end
  end
  if player:isAlive() and #room.alive_players >= aliveBefore then room:loseHp(player, 1, s.name) end
end

s:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasSkill(s.name) and damageCard(card)
  end,
})

s:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasSkill(s.name) and damageCard(card)
  end,
})

s:addEffect(fk.HpChanged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(s.name) and player.hp == 1 and data.old ~= 1 and
      player:getMark(s.name .. "_used") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, s.name .. "_used", 1)
    local place = H.inGeneralSkills(player, s.name)
    if place then H.removeGeneral(player, place == "d") end
    if player:isAlive() then execute(player) end
  end,
})

return s
