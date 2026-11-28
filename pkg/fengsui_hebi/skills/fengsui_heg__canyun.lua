-- 残愠（贾褒）
-- 锁定技，杀死你的角色明置主将并变为野心家。你死亡时，所有野心家角色
-- 依次移除副将并获得〖枯懑〗。
local H = require "packages.fengsui.hegemony_util"

local canyun = fk.CreateSkill {
  name = "fengsui_heg__canyun",
  tags = { Skill.Compulsory },
  related_skills = { "fengsui_heg__kumeng" },
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
  if not player or player.dead then return false end
  -- 先明置主将（暗置时才明置），再变为野心家。
  if player.general == "anjiang" then
    player:revealGeneral(false)
  end
  if H.isWildPlayer(player) then return false end
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
    -- 先让杀死自己的角色明置主将并变为野心家
    local killer = killingSource(room, player)
    if killer then becomeWild(room, killer) end
    -- 所有野心家按座次依次移除副将并获得“枯懑”
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.dead then goto continue end
      if H.isWildPlayer(p) then
        if H.hasGeneral(p, true) then
          H.removeGeneral(p, true)
        end
        room:handleAddLoseSkills(p, "fengsui_heg__kumeng")
      end
      ::continue::
    end
  end,
})

return canyun
