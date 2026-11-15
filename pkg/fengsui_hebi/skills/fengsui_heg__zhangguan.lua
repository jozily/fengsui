local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local zhangguan = fk.CreateSkill {
  name = "fengsui_heg__zhangguan",
  tags = { Skill.Compulsory },
}

local usedMark = "fengsui_heg__zhangguan-turn"
local tagKey = "fengsui_heg__zhangguan"
local hiddenKey = "fengsui_heg__zhangguan_hidden"

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

-- 记下本次用牌，供伤害时机取用。
-- 必须写 aimStruct.extra_data：onAim 在每一轮目标阶段结束后执行
-- useCardData.extra_data = aimStruct.extra_data，只写 data.use.extra_data
-- 会被这一行覆盖，标记随之丢失（两条分支都曾有此问题）。
local function markUse(data, player, direction)
  local extra = data.extra_data or {}
  data.extra_data = extra
  extra[tagKey] = { owner = player.id, direction = direction }
  if data.use then data.use.extra_data = extra end
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
    markUse(data, player, "use")
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
    markUse(data, player, "target")
  end,
})

-- 两条分支记下的牌造成伤害后，若两张武将牌仍明置，暗置本技能对应的武将牌。
-- 「你指定其他角色」与「其他角色指定你」共用这一个时机，标记上不区分方向。
zhangguan:addEffect(fk.DamageCaused, {
  global = true,
  mute = true,
  no_indicate = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not data.card or not player:hasShownSkill(self.name) then return false end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    local use = use_event and use_event.data
    local extra = use and use.extra_data
    local tag = extra and extra[tagKey]
    return tag and tag.owner == player.id and not extra[hiddenKey]
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    local use = use_event and use_event.data
    if use then
      use.extra_data = use.extra_data or {}
      use.extra_data[hiddenKey] = true
    end
    if player:isAlive() and H.allGeneralsRevealed(player) then
      U.hideSkillGeneral(player, self.name)
    end
  end,
})

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
  ["#fengsui_heg__zhangguan-take"] = "仗关：获得 %dest 的一张牌",
  ["#fengsui_heg__zhangguan-give"] = "仗关：选择一张手牌交给 %dest",
}

return zhangguan
