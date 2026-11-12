local H = require "packages.fengsui.hegemony_util"

local shenqing = fk.CreateSkill { name = "fengsui_heg__shenqing" }

-- X 为场上所有角色持有的珠联璧合标记总数。
local function companionMarkCount(room)
  local n = 0
  for _, p in ipairs(room.alive_players) do
    n = n + (tonumber(p:getMark("@!!companion")) or 0)
  end
  return n
end

-- 新版：受到伤害后 / 出牌阶段开始时，令一名角色合璧或摸 X 张牌。
local function commonCost(self, event, player)
  local room = player.room
  local x = companionMarkCount(room)
  local choices = { "fengsui_heg__shenqing_hebi" }
  if x > 0 then table.insert(choices, "fengsui_heg__shenqing_draw") end
  local tos = room:askToChoosePlayers(player, {
    targets = room.alive_players,
    min_num = 1,
    max_num = 1,
    prompt = "#fengsui_heg__shenqing-invoke",
    skill_name = shenqing.name,
    cancelable = true,
  })
  if #tos == 0 then return false end
  local choice = #choices == 1 and choices[1] or room:askToChoice(player, {
    choices = choices,
    skill_name = shenqing.name,
    prompt = "#fengsui_heg__shenqing-choice",
  })
  event:setCostData(self, { to = tos[1], choice = choice, x = x })
  return true
end

local function commonUse(self, event, player)
  local cost = event:getCostData(self)
  local to = cost.to
  if not to or not to:isAlive() then return end
  if cost.choice == "fengsui_heg__shenqing_hebi" then
    H.askToHebiOrTransform(player.room, to, shenqing.name, false)
  else
    to:drawCards(cost.x, shenqing.name)
  end
end

shenqing:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenqing.name)
  end,
  on_cost = function(self, event, target, player, data)
    return commonCost(self, event, player)
  end,
  on_use = function(self, event, target, player, data)
    commonUse(self, event, player)
  end,
})

shenqing:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenqing.name) and
      player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return commonCost(self, event, player)
  end,
  on_use = function(self, event, target, player, data)
    commonUse(self, event, player)
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__shenqing"] = "申情",
  [":fengsui_heg__shenqing"] = "当你受到伤害后或出牌阶段开始时，你可以令一名角色合璧或摸X张牌（X为场上珠联璧合标记数）。",
  ["#fengsui_heg__shenqing-invoke"] = "申情：选择一名角色",
  ["#fengsui_heg__shenqing-choice"] = "申情：请选择一项（可摸 %arg 张牌）",
  ["fengsui_heg__shenqing_hebi"] = "令该角色合璧",
  ["fengsui_heg__shenqing_draw"] = "令该角色摸X张牌",
}

return shenqing
