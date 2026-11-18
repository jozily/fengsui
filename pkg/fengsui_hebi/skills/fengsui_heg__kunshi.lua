-- 检测在"未明确势力视为形成阵形"逻辑下，p1, p2, p3是否构成围攻（p1,p3为围攻，p2被围攻）
local function isKunshiSiege(attacker, victim, support)
  if not attacker or not victim or not support or attacker == victim or attacker == support or victim == support then
    return false
  end
  local attackerKingdom, victimKingdom, supportKingdom = attacker.kingdom, victim.kingdom, support.kingdom
  -- 困势规则：「你的围攻关系内，未确定势力角色视为围攻或被围攻角色」。
  -- 攻击方固定是胡烈（势力已确定），被围攻方 victim 可以是未确定势力——
  -- 此时按规则视作被围攻者，不再要求「与攻击者势力不同」的判定。
  -- 旧代码硬性要求 victimKingdom ~= "unknown"，导致未确定势力角色构成的
  -- 围攻完全不生效（用户报的 bug）。support 侧本来就允许 unknown。
  if victimKingdom == "unknown" then
    return (supportKingdom == attackerKingdom or supportKingdom == "unknown")
  end
  return attackerKingdom ~= "unknown" and
    attackerKingdom ~= victimKingdom and
    (supportKingdom == attackerKingdom or supportKingdom == "unknown")
end

local function checkKunshiSiegeByHuLie(hulie, target, victim)
   if hulie == target then
      local n1 = hulie:getNextAlive()
      local n2 = hulie:getNextAlive(false, 2)
      if n1 == victim and isKunshiSiege(hulie, victim, n2) then return true end
      local l1 = hulie:getLastAlive()
      local l2 = hulie:getLastAlive(false, 2)
      if l1 == victim and isKunshiSiege(hulie, victim, l2) then return true end
   elseif hulie == victim then
      local n1 = hulie:getNextAlive()
      local l1 = hulie:getLastAlive()
      if target == n1 and isKunshiSiege(target, hulie, l1) then return true end
      if target == l1 and isKunshiSiege(target, hulie, n1) then return true end
   end
   return false
end

local kunshi = fk.CreateSkill{
  name = "fengsui_heg__kunshi",
  tags = { Skill.Compulsory },
}
kunshi:addEffect("arraysummon", {
  array_type = "siege",
})
kunshi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kunshi.name) and checkKunshiSiegeByHuLie(player, player, data.to)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})
kunshi:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kunshi.name) and data.from and checkKunshiSiegeByHuLie(player, data.from, player)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

kunshi:addTest(function(room, me)
  local attacker = { kingdom = "jin" }
  local victim = { kingdom = "wei" }
  local support = { kingdom = "unknown" }
  lu.assertTrue(isKunshiSiege(attacker, victim, support))
  support.kingdom = "jin"
  lu.assertTrue(isKunshiSiege(attacker, victim, support))
  support.kingdom = "shu"
  lu.assertFalse(isKunshiSiege(attacker, victim, support))
  -- 被围攻方为未确定势力：按困势规则视为被围攻者，仍构成围攻
  victim.kingdom = "unknown"
  support.kingdom = "jin"
  lu.assertTrue(isKunshiSiege(attacker, victim, support))
  support.kingdom = "unknown"
  lu.assertTrue(isKunshiSiege(attacker, victim, support))
  support.kingdom = "shu"   -- support 为第三方确定势力，不构成
  lu.assertFalse(isKunshiSiege(attacker, victim, support))
end)

Fk:loadTranslationTable{
  ["fengsui_heg__kunshi"] = "困势",
  [":fengsui_heg__kunshi"] = "阵法技，锁定技，当你对被围攻角色造成伤害后，若你是此围攻关系中的围攻角色，此伤害+1；当你受到伤害后，若你是此围攻关系中的被围攻角色，此伤害+1；你的围攻关系内，未确定势力角色视为形成围攻关系的一方。",
}

return kunshi
