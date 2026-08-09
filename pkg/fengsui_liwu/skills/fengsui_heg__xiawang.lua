local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__xiawang" }

local function useLimit(player)
  return math.max(1, #table.filter(player.room.alive_players, function(p)
    return H.compareKingdomWith(p, player)
  end))
end

local function refreshMark(player)
  player.room:setPlayerMark(player, "@" .. s.name,
    tostring(player:getMark(s.name .. "_used")) .. "/" .. tostring(useLimit(player)))
end
s:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(s.name) and player:getMark(s.name .. "_used") < useLimit(player) and
      target:distanceTo(player) <= 1 and data.from and data.from ~= player and
      table.find(player:getCardIds("h"), function(id) local c=Fk:getCardById(id); return c.is_damage_card and player:canUseTo(c, data.from, {bypass_distances=true}) end)
  end,
  on_cost = function(self, event, target, player, data) return player.room:askToSkillInvoke(player, {skill_name=s.name}) end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, s.name .. "_used", 1)
    refreshMark(player)
    local ids = table.filter(player:getCardIds("h"), function(id)
      local card = Fk:getCardById(id)
      return card.is_damage_card and player:canUseTo(card, data.from, { bypass_distances = true })
    end)
    player.room:askToUseRealCard(player, {
      pattern = tostring(Exppattern { id = ids }), skill_name = s.name, cancelable = false,
      extra_data = { exclusive_targets = { data.from.id }, bypass_distances = true, extraUse = true },
    })
  end,
})

s:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(s.name, true, true)
  end,
  on_use = function(self, event, target, player, data) refreshMark(player) end,
})
return s
