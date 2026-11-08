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
    return target and player:hasSkill(aobi.name) and player.room.current == player and data and data.tos
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
    return target == player and player:hasSkill(aobi.name)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local gained = "fengsui_heg__aobi_gained-turn"
    local alive = room.alive_players
    local max, min = -1, math.huge
    for _, p in ipairs(alive) do
      local n = p:getMark(gained)
      max = math.max(max, n)
      min = math.min(min, n)
    end
    -- 本回合无人获得牌时不存在「获得牌最多/最少的角色」，不结算。
    if max <= 0 then return end
    local most = table.filter(alive, function(p) return p:getMark(gained) == max end)
    local least = table.filter(alive, function(p) return p:getMark(gained) == min end)
    if #most == 1 then
      -- 最多者唯一：其依次对所有获得牌最少的其他角色各造成 1 点伤害。
      local source = most[1]
      for _, p in ipairs(least) do
        if p ~= source and source:isAlive() and p:isAlive() then
          room:damage { from = source, to = p, damage = 1, skillName = aobi.name }
        end
      end
    else
      -- 最多者不唯一：获得牌最少的角色依次对所有获得牌最多的其他角色各造成 1 点伤害。
      for _, p in ipairs(least) do
        for _, source in ipairs(most) do
          if p ~= source and p:isAlive() and source:isAlive() then
            room:damage { from = p, to = source, damage = 1, skillName = aobi.name }
          end
        end
      end
    end
  end,
})

return aobi
