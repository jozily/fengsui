local H = require "packages.fengsui.hegemony_util"
local tishi = fk.CreateSkill { name = "fengsui_heg__tishi", tags = { Skill.Compulsory } }

-- 暗置武将的技能只处于预亮状态，@ 标记却仍会公开显示，等于提前暴露武将。
-- 因此可见标记一律以 hasShownSkill 为准：暗置时清空，明置时按剩余次数补齐。
local function updateVisible(room, player)
  if not player:hasShownSkill(tishi.name) then
    if player:getMark("@fengsui_heg__tishi") ~= 0 then
      room:setPlayerMark(player, "@fengsui_heg__tishi", 0)
    end
    return
  end
  local remain = {}
  for _, n in ipairs({3, 2, 1}) do
    if player:getMark("fengsui_heg__tishi-" .. n .. "-round") == 0 then table.insert(remain, tostring(n)) end
  end
  local value = table.concat(remain, " ")
  if player:getMark("@fengsui_heg__tishi") ~= value then
    room:setPlayerMark(player, "@fengsui_heg__tishi", value)
  end
end

tishi:addEffect(fk.HpChanged, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(self.name) and data and data.old ~= player.hp and
      (player.hp == 3 or player.hp == 2 or player.hp == 1) and player:getMark("fengsui_heg__tishi-" .. player.hp .. "-round") == 0
  end,
  on_use = function(self, _, _, player)
    local room, n = player.room, player.hp
    room:setPlayerMark(player, "fengsui_heg__tishi-" .. n .. "-round", 1)
    updateVisible(room, player)
    if n == 3 then H.addHegMark(player, "yinyangfish") elseif n == 2 then H.addHegMark(player, "vanguard") elseif n == 1 then
      local card = Fk:cloneCard("thunder__slash")
      local targets = table.filter(room:getOtherPlayers(player), function(p) return player:canUseTo(card, p, { bypass_times = true }) end)
      if #targets > 0 then
        local tos = room:askToChoosePlayers(player, { targets = targets, min_num = 1, max_num = 1, cancelable = false, skill_name = self.name, prompt = "#fengsui_heg__tishi-slash" })
        if #tos > 0 then room:useVirtualCard("thunder__slash", nil, player, tos[1], self.name, true) end
      end
    end
  end,
})
tishi:addEffect(fk.RoundStart, { global = true,
  can_refresh = function(self, _, target, player)
    return target ~= nil and player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, _, target, player)
    local room = player.room
    for _, p in ipairs(room.players) do
      if p:hasSkill(self.name, true) then
        for _, n in ipairs({ 1, 2, 3 }) do room:setPlayerMark(p, "fengsui_heg__tishi-" .. n .. "-round", 0) end
        updateVisible(room, p)
      end
    end
  end,
})

-- 明置 / 暗置发生的当下就更新显示，不等下一轮开始。暗置流程会剥技能，
-- 所以用 global refresh 无条件重算全场；updateVisible 自带去重，重复执行
-- 不会产生多余的同步包。
for _, event in ipairs({ fk.GeneralRevealed, fk.GeneralHidden }) do
  tishi:addEffect(event, { global = true,
    can_refresh = function() return true end,
    on_refresh = function(self, _, target, player)
      local room = player.room
      for _, p in ipairs(room.players) do updateVisible(room, p) end
    end,
  })
end

return tishi
