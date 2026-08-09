local H = require "packages.fengsui.hegemony_util"

-- 检测在"未明确势力视为形成阵形"逻辑下，p1, p2, p3是否构成围攻（p1,p3为围攻，p2被围攻）
local function isKunshiSiege(p1, p2, p3)
   local k1, k2, k3 = p1.kingdom, p2.kingdom, p3.kingdom
   local siegeSide = {}
   if k1 ~= "unknown" then table.insertIfNeed(siegeSide, k1) end
   if k3 ~= "unknown" then table.insertIfNeed(siegeSide, k3) end
   if #siegeSide > 1 then return false end
   local s_k = siegeSide[1]
   if s_k and k2 ~= "unknown" and s_k == k2 then return false end
   return true
end

local function checkKunshiSiegeByHuLie(hulie, target, victim)
   if hulie == target then
      local n1 = hulie:getNextAlive()
      local n2 = hulie:getNextAlive(false, 2)
      if n1 == victim and isKunshiSiege(hulie, n1, n2) then return true end
      local l1 = hulie:getLastAlive()
      local l2 = hulie:getLastAlive(false, 2)
      if l1 == victim and isKunshiSiege(l2, l1, hulie) then return true end
   elseif hulie == victim then
      local n1 = hulie:getNextAlive()
      local l1 = hulie:getLastAlive()
      if isKunshiSiege(l1, hulie, n1) then return true end
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

Fk:loadTranslationTable{
  ["fengsui_heg__kunshi"] = "困势",
  [":fengsui_heg__kunshi"] = "阵法技，锁定技，当你对被围攻角色造成伤害后，若你是此围攻关系中的围攻角色，此伤害+1；当你受到伤害后，若你是此围攻关系中的被围攻角色，此伤害+1；你的围攻关系内，未确定势力角色视为形成围攻关系的一方。",
}

return kunshi
