-- 残愠（贾褒）
-- 锁定技，当你死亡时，你令所有伤害来源和野心家角色移除副将，
-- 且与你势力相同的角色依次对其造成一点伤害。
local H = require "packages.fengsui.hegemony_util"

local canyun = fk.CreateSkill {
  name = "fengsui_heg__canyun",
  tags = { Skill.Compulsory },
}

local function damageSources(room, dead)
  local sources = {}
  for _, e in ipairs(room.logic:getEventsOfScope(GameEvent.Damage, 9999, function() return true end, Player.HistoryGame)) do
    local damage = e.data
    if e.exec_ret == true and damage and damage.to == dead and damage.from and damage.from:isAlive() then
      table.insertIfNeed(sources, damage.from)
    end
  end
  return sources
end

canyun:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    if target ~= player or not player:hasSkill(canyun.name, false, true) then return false end
    local room = player.room
    return #damageSources(room, player) > 0 or
      table.find(room.alive_players, function(p) return H.getKingdom(p) == "wild" end) ~= nil
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local kingdom = H.getKingdom(player)
    local affected = damageSources(room, player)
    for _, p in ipairs(room:getAlivePlayers()) do
      if H.getKingdom(p) == "wild" then table.insertIfNeed(affected, p) end
    end
    for _, p in ipairs(affected) do
      -- 移除副将（普通移除，非废除）
      if H.hasGeneral(p, true) then
        H.removeGeneral(p, true, canyun.name)
      end
      -- 与你势力相同的角色依次对其造成一点伤害（也包括其自身若同势力）
      for _, ally in ipairs(room:getAlivePlayers()) do
        if H.getKingdom(ally) == kingdom then
          room:damage { from = ally, to = p, damage = 1, skillName = canyun.name }
        end
      end
    end
  end,
})

return canyun
