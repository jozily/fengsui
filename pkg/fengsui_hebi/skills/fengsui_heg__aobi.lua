local aobi = fk.CreateSkill {
  name = "fengsui_heg__aobi",
  tags = { Skill.Compulsory },
}

local previousUser = "fengsui_heg__aobi_previous_user-turn"
local previousTargets = "fengsui_heg__aobi_previous_targets-turn"

local function targetIds(data)
  return table.map(data and data.tos or {}, function(p) return p.id end)
end

aobi:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and player:hasShownSkill(aobi.name) and player.room.current == player and data and data.tos
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local oldUser = player:getMark(previousUser)
    local oldTargets = player:getTableMark(previousTargets)
    local currentTargets = targetIds(data)
    if oldUser == target.id then
      local common = table.filter(currentTargets, function(id) return table.contains(oldTargets, id) end)
      for _, id in ipairs(common) do
        local p = room:getPlayerById(id)
        if p and p:isAlive() then p:drawCards(1, aobi.name) end
      end
    end
    room:setPlayerMark(player, previousUser, target.id)
    room:setPlayerMark(player, previousTargets, #currentTargets > 0 and currentTargets or 0)
  end,
})

aobi:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, _, _, player, data)
    return data ~= nil
  end,
  on_refresh = function(self, _, _, player, data)
    for _, move in ipairs(data) do
      if move.to and move.toArea ~= Card.Processing and move.moveInfo then
        player.room:addPlayerMark(move.to, "fengsui_heg__aobi_gained-turn", #move.moveInfo)
      end
    end
  end,
})

aobi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(aobi.name)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local max = -1
    for _, p in ipairs(room.alive_players) do max = math.max(max, p:getMark("fengsui_heg__aobi_gained-turn")) end
    if max <= 0 then return end
    local most = table.filter(room.alive_players, function(p)
      return p:getMark("fengsui_heg__aobi_gained-turn") == max
    end)
    local none = table.filter(room.alive_players, function(p)
      return p:getMark("fengsui_heg__aobi_gained-turn") == 0 and not table.contains(most, p)
    end)
    local reverse = #most > 1 and not table.contains(most, player)
    if reverse then
      for _, p in ipairs(none) do
        for _, source in ipairs(most) do
          if p:isAlive() and source:isAlive() then room:damage { from = p, to = source, damage = 1, skillName = aobi.name } end
        end
      end
    else
      for _, source in ipairs(most) do
        for _, p in ipairs(none) do
          if source:isAlive() and p:isAlive() then room:damage { from = source, to = p, damage = 1, skillName = aobi.name } end
        end
      end
    end
  end,
})

return aobi
