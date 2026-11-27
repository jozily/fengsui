-- 残愠（贾褒）
-- 锁定技，当你死亡时，伤害来源所属势力所有角色依次选择一项：
-- 1.失去一点体力；2.移除副将。
local H = require "packages.fengsui.hegemony_util"

local canyun = fk.CreateSkill {
  name = "fengsui_heg__canyun",
  tags = { Skill.Compulsory },
}

local function damageSources(room, dead)
  local sources = {}
  for _, e in ipairs(room.logic:getEventsOfScope(GameEvent.Damage, 9999, function() return true end, Player.HistoryGame)) do
    local damage = e.data
    if e.exec_ret == true and damage and damage.to == dead and damage.from then
      table.insertIfNeed(sources, damage.from)
    end
  end
  return sources
end

canyun:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    if target ~= player or not player:hasSkill(canyun.name, false, true) then return false end
    return #damageSources(player.room, player) > 0
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    -- 受影响者按座次取自伤害来源所属势力；多个来源取势力并集。
    local kingdoms = {}
    for _, src in ipairs(damageSources(room, player)) do
      local kingdom = H.getKingdom(src)
      if kingdom and kingdom ~= "unknown" then table.insertIfNeed(kingdoms, kingdom) end
    end
    local affected = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if table.contains(kingdoms, H.getKingdom(p)) then
        table.insert(affected, p)
      end
    end
    for _, p in ipairs(affected) do
      if p.dead then goto continue end
      local choices = { "fengsui_heg__canyun_losehp" }
      if H.hasGeneral(p, true) then table.insert(choices, "fengsui_heg__canyun_remove") end
      local choice = #choices == 1 and choices[1] or room:askToChoice(p, {
        choices = choices,
        skill_name = canyun.name,
        prompt = "#fengsui_heg__canyun-choice",
      })
      if choice == "fengsui_heg__canyun_remove" then
        H.removeGeneral(p, true)
      else
        room:loseHp(p, 1, canyun.name)
      end
      ::continue::
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__canyun-choice"] = "残愠：请选择一项",
  ["fengsui_heg__canyun_losehp"] = "失去一点体力",
  ["fengsui_heg__canyun_remove"] = "移除副将",
}

return canyun
