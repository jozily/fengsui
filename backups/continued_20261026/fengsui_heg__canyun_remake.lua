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
      local choices = { "fengsui_heg__canyun_damage" }
      if H.hasGeneral(p, true) then table.insert(choices, "fengsui_heg__canyun_remove") end
      local choice = room:askToChoice(p, {
        choices = choices,
        skill_name = canyun.name,
        prompt = "#fengsui_heg__canyun-choice",
      })
      if choice == "fengsui_heg__canyun_remove" then
        H.removeGeneral(p, true, canyun.name)
        room:setPlayerMark(p, "@fengsui_heg__abolish_deputy", 1)
      else
        for _, ally in ipairs(room:getAlivePlayers()) do
          if ally ~= p and H.getKingdom(ally) == kingdom then
            room:damage { from = ally, to = p, damage = 1, skillName = canyun.name }
          end
        end
      end
    end
  end,
})

-- 废除副将后的通用限制：副将已经由士兵替代，之后任何变更副将的请求都被拦截。
canyun:addEffect(H.GeneralTransforming, {
  global = true,
  can_trigger = function(self, _, target, _, data)
    return target and data and not data.isMain and
      (target:getMark("@fengsui_heg__abolish_deputy") > 0 or
        target:getMark("@fengsui_heg__canyun_nochange") > 0 or
        target:getMark("@fengsui_heg__xunyun_nochange") > 0)
  end,
  on_use = function() return true end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__canyun-choice"] = "残愠：请选择一项",
  ["fengsui_heg__canyun_damage"] = "令与你势力相同的角色依次对你造成一点伤害",
  ["fengsui_heg__canyun_remove"] = "废除副将",
  ["@fengsui_heg__abolish_deputy"] = "废除副将",
  ["@fengsui_heg__canyun_nochange"] = "废除副将",
}

return canyun
