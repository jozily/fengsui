local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local zhangguan = fk.CreateSkill {
  name = "fengsui_heg__zhangguan",
  tags = { Skill.Compulsory },
}

local function firstTarget(data)
  if data.to then return data.to end
  local targets = data.use and data.use:getAllTargets() or {}
  return targets[1]
end

local function markUse(data, owner, direction)
  data.use.extra_data = data.use.extra_data or {}
  data.use.extra_data.fengsui_heg__zhangguan = {
    owner = owner.id,
    direction = direction,
  }
end

-- 你首次使用牌指定目标：获得第一个目标的一张牌。
zhangguan:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.firstTarget and player:hasSkill(self.name, true) and
      player:getMark("fengsui_heg__zhangguan-turn") == 0 and firstTarget(data) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__zhangguan-turn", 1)
    local to = firstTarget(data)
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

-- 他人首次使用牌指定你：其获得你的一张手牌。
zhangguan:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.from and data.from ~= player and player:hasSkill(self.name, true) and
      player:getMark("fengsui_heg__zhangguan-turn") == 0 and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__zhangguan-turn", 1)
    local id = room:askToChooseCard(data.from, {
      target = player, flag = "h", skill_name = self.name,
      prompt = "#fengsui_heg__zhangguan-give::" .. player.id,
    })
    if id then room:obtainCard(data.from, id, true, fk.ReasonGive, player, self.name) end
    markUse(data, player, "target")
  end,
})

-- 记录的牌造成伤害后，若两张武将牌仍明置，暗置本技能对应的武将牌。
zhangguan:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not data.card or not player:hasSkill(self.name, true) then return false end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    local use = use_event and use_event.data
    return use and use.extra_data and use.extra_data.fengsui_heg__zhangguan and
      use.extra_data.fengsui_heg__zhangguan.owner == player.id and
      not use.extra_data.fengsui_heg__zhangguan_hidden
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    local use = use_event and use_event.data
    if use then use.extra_data.fengsui_heg__zhangguan_hidden = true end
    if player:isAlive() and U.allGeneralsRevealed(player) then U.hideSkillGeneral(player, self.name) end
  end,
})

zhangguan:addEffect(fk.TurnStart, {
  global = true, mute = true,
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("fengsui_heg__zhangguan-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "fengsui_heg__zhangguan-turn", 0)
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__zhangguan-take"] = "仗关：获得 %dest 的一张牌",
  ["#fengsui_heg__zhangguan-give"] = "仗关：选择一张手牌交给 %dest",
}

return zhangguan
