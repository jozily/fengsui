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

-- 本回合仗关结算过之后，只要牵涉到伤害，且两张武将牌仍明置，就暗置此武将牌。
-- fk.DamageCaused 的 target 是伤害来源，覆盖「你指定其他角色」后你打伤别人；
-- fk.DamageInflicted 的 target 是受伤者，补上「其他角色指定你」后你被打伤。
-- 旧实现只有 DamageCaused，别人打马邈时 target 是对方，马邈受伤不会暗置。
-- 不再依赖 use.extra_data 传递标记：onAim 每轮会用 aimStruct.extra_data
-- 覆盖 useCardData.extra_data，标记容易丢失；改用本回合的 usedMark 判定，
-- 且暗置后 hasShownSkill 自动变假，同一次伤害链不会重复结算。
local function hideWhenDamaged(self, _, target, player, data)
  if target ~= player or not data or (data.damage or 0) < 1 then return false end
  return player:hasShownSkill(self.name) and player:getMark(usedMark) ~= 0 and
    player:isAlive() and H.allGeneralsRevealed(player)
end

local hideSpec = {
  is_delay_effect = true,
  mute = true,
  no_indicate = true,
  can_trigger = hideWhenDamaged,
  on_cost = function() return true end,
  on_use = function(self, event, target, player)
    if player:isAlive() and H.allGeneralsRevealed(player) then
      U.hideSkillGeneral(player, self.name)
    end
  end,
}
zhangguan:addEffect(fk.DamageCaused, hideSpec)
zhangguan:addEffect(fk.DamageInflicted, hideSpec)

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
