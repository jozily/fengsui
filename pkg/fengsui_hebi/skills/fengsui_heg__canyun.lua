-- 残愠（贾褒）
-- 锁定技，杀死你的角色变为野心家。你死亡时，所有野心家角色弃置其“野心家”
-- 标记并选择一项：1.移除副将；2.失去一点体力。
local H = require "packages.fengsui.hegemony_util"

local canyun = fk.CreateSkill {
  name = "fengsui_heg__canyun",
  tags = { Skill.Compulsory },
}

-- 致命伤害来源：取本局最后一次对死者造成且生效的伤害来源。
local function killingSource(room, dead)
  local source
  for _, e in ipairs(room.logic:getEventsOfScope(GameEvent.Damage, 9999, function() return true end, Player.HistoryGame)) do
    local damage = e.data
    if e.exec_ret == true and damage and damage.to == dead and damage.from and damage.from ~= dead then
      source = damage.from
    end
  end
  return source
end

local function becomeWild(room, player)
  if not player or player.dead or H.isWildPlayer(player) then return false end
  room:setPlayerMark(player, "__heg_wild", 1)
  room:setPlayerProperty(player, "kingdom", "wild")
  -- 野心家当场建国：立刻结算势力选择
  H.wildChooseKingdom(player, player.general)
  return true
end

canyun:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(canyun.name, false, true)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    -- 先让杀死自己的角色变为野心家
    local killer = killingSource(room, player)
    if killer then becomeWild(room, killer) end
    -- 所有野心家按座次弃置“野心家”标记，再选择一项
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.dead then goto continue end
      if H.isWildPlayer(p) then
        if p:getMark("@!!wild") > 0 then
          H.removeHegMark(room, p, "wild", 1)
        end
        local choices = { "fengsui_heg__canyun_losehp" }
        if H.hasGeneral(p, true) then
          table.insert(choices, 1, "fengsui_heg__canyun_remove")
        end
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
