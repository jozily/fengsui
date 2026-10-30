-- 醒寂：每回合限一次。当一名角色于一回合内连续发动两次相同的技能后，
-- 你可以对其造成1点火焰伤害；若其势力与你相同，你视为未发动「酣世」。
--
-- 实现要点（改之前务必先读）：
--   ① 本技能只有一条效果，因此它自动成为牌面与技能栏里的「醒寂」，只向拥有者询问一次。
--   ② 发动序列不用触发技记录，而是包一层 Room.useSkill 直接记账。原因在引擎的触发循环：
--      效果技只要没写 can_trigger，TriggerSkill:triggerable 的默认实现就认为它「随时可发动」
--      （global 效果更是对每个座位都成立，且 Skill:isPlayerSkill 并不检查技能归属），
--      于是同一优先级下只要凑够两项，就会弹出「选择要发动的技能」选框
--      （trigger_event.lua:158）。记账是纯事务，不该进任何询问流程，否则每结算一次技能
--      效果，场上每个人都会被问一次，选框里还会出现空标题项。
--   ③ 序列标记带 -turn 后缀，回合边界交给 Room:clearHistory 统一清空，技能自己不计时。
local H = require "packages.fengsui.hegemony_util"

local xingji = fk.CreateSkill {
  name = "fengsui_heg__xingji",
}

-- 本回合内各角色发动过的技能，按时间顺序追加
local chainMark = "fengsui_heg__xingji_chain-turn"
-- 本回合醒寂是否已经发动过
local usedMark = "fengsui_heg__xingji_used-turn"

-- 只有「发动技能」才记账：使用牌、装备自身的效果都不算
local function recordableName(skill)
  if not skill then return nil end
  if skill.cardSkill then return nil end
  local skeleton = skill:getSkeleton()
  if not skeleton or skeleton.attached_equip then return nil end
  local name = skeleton.name
  if not name or name == "" or name == xingji.name or name:sub(1, 1) == "#" then return nil end
  return name
end

-- 技能效果的唯一入口。挂在这里记账的好处是：不产生触发技、不参与任何询问，
-- 且天然按发动先后排序；本次技能在 SkillEffect/AfterSkillEffect 之前就已入列。
local RoomClass = Room
if not RoomClass then
  -- 服务端启动后才把 Room 挂到全局，这里兜一层，避免加载顺序不同就静默失效
  local ok, mod = pcall(require, "ltk.server.room")
  if ok then RoomClass = mod end
end

if type(RoomClass) == "table" and RoomClass.useSkill and not RoomClass._fengsuiXingjiChainHooked then
  RoomClass._fengsuiXingjiChainHooked = true
  local originalUseSkill = RoomClass.useSkill
  RoomClass.useSkill = function(self, player, skill, effect_cb, skill_data)
    local name = recordableName(skill)
    if name and player then
      self:addTableMark(player, chainMark, name)
    end
    return originalUseSkill(self, player, skill, effect_cb, skill_data)
  end
end

-- 序列末尾连续两个同名技能即「一回合内连续发动两次相同的技能」
local function repeatedTwice(target, name)
  local chain = target:getTableMark(chainMark)
  return #chain >= 2 and chain[#chain] == name and chain[#chain - 1] == name
end

-- ── 判定：序列里刚出现两个相同的技能时，问拥有者是否打这 1 点火焰伤害 ──
-- 这是本技能唯一的效果，也就是牌面与技能栏里的「醒寂」。
xingji:addEffect(fk.AfterSkillEffect, {
  can_trigger = function(self, _, target, player, data)
    if target == nil or target == player then return false end
    if not player:isAlive() or not player:hasSkill(xingji.name) then return false end
    if player:getMark(usedMark) > 0 then return false end
    local name = recordableName(data and data.skill)
    if not name then return false end
    return repeatedTwice(target, name)
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = xingji.name,
      prompt = "#fengsui_heg__xingji-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local sameKingdom = H.compareKingdomWith(player, target)
    room:setPlayerMark(player, usedMark, 1)
    room:damage {
      from = player,
      to = target,
      damage = 1,
      damageType = fk.FireDamage,
      skillName = xingji.name,
    }
    if sameKingdom then
      player:setSkillUseHistory("fengsui_heg__hanshi", 0, Player.HistoryGame)
    end
  end,
})

return xingji
