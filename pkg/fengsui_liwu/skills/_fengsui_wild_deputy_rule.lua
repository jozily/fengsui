-- 烽燧之战 · 「野心家副将」规则
--
-- 规则本体收敛在 packages/fengsui/hegemony_util.lua 的 compat.transformGeneral：
-- 包内所有「变更副将」入口都经该总闸门，野心家变更副将时随机抽取一张
-- 任意势力武将直接变更，不再按自身势力筛选。
-- 合璧是另一套机制：野心家势力主将可正常合璧，合璧候选池排除野心家势力
-- 与中立者武将（上层规则）。
-- 本文件只提供游戏内可见的规则说明与一条变更日志，不重复实现换将。
local H = require "packages.fengsui.hegemony_util"

local wildDeputyRule = fk.CreateSkill {
  name = "#fengsui_heg__wild_deputy_rule",
  mute = true,
  no_indicate = true,
  global = true,
}

wildDeputyRule:addEffect(H.GeneralTransformed, {
  global = true,
  mute = true,
  -- priority<=0 走引擎静默自动触发路径，不会与其他监听者同时可触发时
  -- 弹出「选择发动的技能」框；on_cost 直接返回 true 关掉询问。
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and data and data.fengsuiWildDeputy == true
  end,
  -- 只发一条日志，不弹询问、不暴露暗置副将的名称。
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:sendLog{
      type = "#fengsui_wild_deputy_rule",
      from = player.id,
    }
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__wild_deputy_rule"] = "野心家副将",
  [":#fengsui_heg__wild_deputy_rule"] =
    "锁定技，野心家变更副将时，随机将副将变更为任意势力的一名武将。",
  ["#fengsui_wild_deputy_rule"] = "%from 为野心家，随机变更副将（任意势力）",
}

return wildDeputyRule
