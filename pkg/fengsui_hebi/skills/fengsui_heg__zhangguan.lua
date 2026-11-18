local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local zhangguan = fk.CreateSkill {
  name = "fengsui_heg__zhangguan",
  tags = { Skill.Compulsory },
}

local usedMark = "fengsui_heg__zhangguan-turn"

-- 本次用牌所指定的「第一个其他角色」。
-- 「你指定其他角色」按整张牌的目标表判断：即便第一个目标是自己，
-- 只要后面还有别的角色，也算指定了其他角色。
local function firstOtherTarget(data, player)
  local use = data.use
  if not use then return nil end
  -- 使用牌的 tos 此时仍是完整目标表；不取 getAllTargets，避免 TriggerData
  -- 的 __index 代理在方法查找上出问题。
  for _, p in ipairs(use.tos or {}) do
    if p and p ~= player and p:isAlive() then return p end
  end
  return nil
end

-- 你首次指定其他角色：获得所指定的第一个其他角色的一张牌。
zhangguan:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.firstTarget and player:hasShownSkill(self.name) and
      player:getMark(usedMark) == 0 and firstOtherTarget(data, player) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, usedMark, 1)
    local to = firstOtherTarget(data, player)
    if to and not to:isKongcheng() then
      local id = room:askToChooseCard(player, {
        target = to, flag = "he", skill_name = self.name,
        prompt = "#fengsui_heg__zhangguan-take::" .. to.id,
      })
      if id then room:obtainCard(player, id, true, fk.ReasonPrey, player, self.name) end
    end
  end,
})

-- 其他角色首次指定你：其获得你的一张手牌。
zhangguan:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.from and data.from ~= player and
      player:hasShownSkill(self.name) and player:getMark(usedMark) == 0 and
      not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, usedMark, 1)
    local id = room:askToChooseCard(data.from, {
      target = player, flag = "h", skill_name = self.name,
      prompt = "#fengsui_heg__zhangguan-give::" .. player.id,
    })
    if id then room:obtainCard(data.from, id, true, fk.ReasonGive, player, self.name) end
  end,
})

-- 本回合仗关结算过之后，只要这张牌造成了伤害，且两张武将牌仍明置，就暗置此武将牌。
--
-- 旧实现把判定挂在伤害结算【前】的 DamageCaused / DamageInflicted，且要求
-- data.damage >= 1：伤害被护甲吸收（实际扣血为 0）、或目标牌的目标确认交互
-- 被打断时 usedMark 未及时置位，都会漏判，于是出现「马邈受伤且武将均明置
-- 却仍不暗置」。改为挂在伤害结算【后】的 fk.Damaged：此时伤害已确实发生，
-- 不再看 data.damage 的数值门槛，只看「本回合仗关已结算 + 双方明置」。
-- global=true 让「马邈造成别人伤害」(data.from 是马邈) 与「别人伤害马邈」
-- (target 是马邈) 两种情形都能扫到；暗置后 hasShownSkill 变假，天然不重复。
local function hideWhenDamaged(self, _, target, player, data)
  if not player:isAlive() or not player:hasShownSkill(self.name) then return false end
  if player:getMark(usedMark) == 0 then return false end
  if not H.allGeneralsRevealed(player) then return false end
  if not data then return false end
  -- 马邈是受伤者，或马邈是伤害来源，都算这张牌牵涉到他
  return target == player or data.from == player
end

local hideSpec = {
  global = true,
  is_delay_effect = true,
  mute = true,
  no_indicate = true,
  can_trigger = hideWhenDamaged,
  on_cost = function() return true end,
  on_use = function(self, event, target, player)
    if not (player:isAlive() and H.allGeneralsRevealed(player)) then return end
    -- 优先暗置仗关所在的那张武将牌；若因合璧/变更副将找不到归位，退而暗置主将，
    -- 保证「受伤即暗置」不会被 getSkillPlace 返回 nil 卡住。
    if not U.hideSkillGeneral(player, self.name) then
      if player.general ~= "anjiang" then player:hideGeneral(false) end
    end
  end,
}
zhangguan:addEffect(fk.Damaged, hideSpec)

zhangguan:addEffect(fk.TurnStart, {
  global = true, mute = true,
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark(usedMark) ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, usedMark, 0)
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__zhangguan-take"] = "仗关：选择获得 %dest 的一张牌",
  ["#fengsui_heg__zhangguan-give"] = "仗关：选择获得 %dest 的一张手牌",
}

return zhangguan
