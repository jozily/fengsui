-- 武将变更 / 移除后，清理技能留在角色身上的临时标记。
--
-- 做法：不修改 packages/hegemony 的源文件，也不逐门技能去补 on_lose，
-- 而是在风随包里包装两个必经入口：
--   1. Room:changeHero —— 官方与风随的「换将」路径都走它；
--   2. H.GameEvent.RemoveGeneral.main —— 官方「移除武将牌」路径不走
--      changeHero，只卸技能后直接改 general 属性，必须单独兜住。
-- 变更前先记下该角色当前持有的登记技能，变更完成后按表清标记。
--
-- 普通明置 / 暗置不触发清理：明置虽也走 changeHero，但传入的武将名
-- 与 __heg_general / __heg_deputy 里记录的暗将名相同，据此跳过；暗置走
-- setPlayerGeneral + hideGeneral，根本不经过 changeHero。这样心幽每回合
-- 暗置自己时，本局累计的次数不会被抹掉。
--
-- 登记表只列明确需要清理的技能与标记，不做前缀推断；跨角色、设计上
-- 应长期保留的效果（国战标记、觉醒与限定次数、累计历史）一律不登记。

local H = require "packages.hegemony.util"
local U = require "packages.utility.utility"
local FU = require "packages.fengsui.pkg.fengsui_liwu.util"

-- self_marks：只清变更者自己身上的；all_marks：标记挂在别人身上，遍历全场清。
-- extra：需要连带归还武将牌 / 卸掉临时技能等额外动作。
local CLEANUP = {
  -- 烽燧燎原：界面可见的定格数字、势力名串、次数显示。
  ["fengsui_heg__tishi"] = {
    self_marks = { "@fengsui_heg__tishi" },
  },
  ["fengsui_heg__xinyou"] = {
    self_marks = { "@fengsui_heg__xinyou", "fengsui_heg__xinyou_count" },
  },
  ["fengsui_heg__yuandi"] = {
    self_marks = { "@fengsui_heg__yuandi", "@fengsui_heg__xinyou", "fengsui_heg__xinyou_count" },
  },
  ["fengsui_heg__zhuiji"] = {
    -- -disabled 若不清，日後重获技能会一直无法发动。
    self_marks = {
      "@fengsui_heg__zhuiji",
      "fengsui_heg__zhuiji-disabled",
      "fengsui_heg__zhuiji-damage",
    },
  },
  ["fengsui_heg__yanshi"] = {
    -- 配对目标记在自己身上，可见标记挂在对方身上。
    self_marks = { "fengsui_heg__yanshi_target" },
    all_marks = { "@fengsui_heg__yanshi_target" },
  },

  -- 官方国战：回合性效果换将后仍生效 / 显示残留。
  ["hs__luoyi"] = {
    self_marks = { "@@hs__luoyi" },
  },
  ["ty_heg__zhuihuan"] = {
    all_marks = { "@@ty_heg__zhuihuan_damage", "@@ty_heg__zhuihuan_discard" },
  },
  ["ofl_heg__dianhu"] = {
    self_marks = { "ofl_heg__dianhu" },
    all_marks = { "@@ofl_heg__dianhu" },
  },
  ["jianan"] = {
    -- 君主换将后，被选角色会永久不能明置、临时技能也无人回收。
    -- RevealProhibited 与青龙刀共用同一个无后缀 mark，官方 on_refresh
    -- 无条件清全场会连带清掉青龙刀正在生效的禁亮；这里只摘掉建安自己
    -- 那一项（由 official_overrides 的 fengsui_jianan_reveal 记录）。
    extra = function(room, player)
      for _, p in ipairs(room.players) do
        local skills = p:getMark("@jianan_skills")
        if type(skills) == "table" and #skills > 0 then
          pcall(function()
            room:handleAddLoseSkills(p, "-" .. table.concat(skills, "|-"), nil, false, true)
          end)
        end
        local rec = p:getTableMark(MarkEnum.RevealProhibited)
        local flag = p:getMark("fengsui_jianan_reveal")
        if type(flag) == "string" and (flag == "m" or flag == "d") then
          table.removeOne(rec, flag)
          room:setPlayerMark(p, MarkEnum.RevealProhibited, #rec == 0 and 0 or rec)
        else
          -- 没有记录时按青龙刀层数重建，仍不整表清零。
          local n = p:getMark("@@sa__blade")
          local rebuilt = {}
          for _ = 1, n do
            table.insert(rebuilt, "m")
            table.insert(rebuilt, "d")
          end
          room:setPlayerMark(p, MarkEnum.RevealProhibited, #rebuilt == 0 and 0 or rebuilt)
        end
        room:setPlayerMark(p, "@jianan_skills", 0)
        room:setPlayerMark(p, "fengsui_jianan_reveal", 0)
      end
    end,
  },

  -- 存疑三项，按用户要求：对应武将变更 / 移除时一并清除。
  ["ty_heg__zhiwei"] = {
    self_marks = { "ty_heg__zhiwei", "@zhiwei" },
  },
  ["fengsui_heg__yingmen"] = {
    -- 访客武将牌要归还将池，灌入的临时技能要摘掉，初始化标记归零。
    extra = function(room, player)
      local visitors = U.getPrivateMark(player, "&fengsui_heg__fangke")
      if type(visitors) == "table" and #visitors > 0 then
        pcall(function() room:returnToGeneralPile(visitors) end)
      end
      for _, skillName in ipairs(player:getTableMark("fengsui_heg__fangke_skills")) do
        local skill = Fk.skills[skillName]
        if skill then
          pcall(function()
            player:prelightSkill(skill, false)
            player:loseFakeSkill(skill)
          end)
        end
      end
      for _, name in ipairs({
        "fengsui_heg__fangke_skills",
        "@[private]&fengsui_heg__fangke",
        "fengsui_heg__yingmen_initialized",
      }) do
        if player:getMark(name) ~= 0 then room:setPlayerMark(player, name, 0) end
      end
      pcall(function() FU.expireVisitorSkills(room, player) end)
    end,
  },
  ["ld__yigui"] = {
    -- 「魂」是扣置的武将牌，必须归还将池，不能只清显示标记。
    extra = function(room, player)
      local hun = U.getPrivateMark(player, "&ld__hun")
      if type(hun) == "table" and #hun > 0 then
        pcall(function() room:returnToGeneralPile(hun) end)
      end
      for _, name in ipairs({
        "@[private]&ld__hun",
        "ld__yigui_cards",
        "ld__yigui_show",
        "ld__yigui_extra_data",
      }) do
        if player:getMark(name) ~= 0 then room:setPlayerMark(player, name, 0) end
      end
    end,
  },
}

local function clearMarks(room, player, names, allPlayers)
  if not names then return end
  local targets = allPlayers and room.players or { player }
  for _, p in ipairs(targets) do
    for _, name in ipairs(names) do
      if p:getMark(name) ~= 0 then
        room:setPlayerMark(p, name, 0)
      end
    end
  end
end

local function snapshot(player)
  local owned = {}
  if not player or not player.room then return owned end
  for name in pairs(CLEANUP) do
    if player:hasSkill(name) then owned[#owned + 1] = name end
  end
  return owned
end

-- 青龙刀：标记挂在【杀】的目标身上，与谁换将无关。若场上已无人持有
-- 这把装备的技能，说明结算结束时官方 refresh 没跑，这里补清残留。
-- 建安那一项仍由 fengsui_jianan_reveal 记录并补回，避免互相误伤。
local function cleanupBladeResidual(room)
  for _, p in ipairs(room.players) do
    if p:hasSkill("#sa__blade_skill", true, true) then return end
  end
  for _, p in ipairs(room.players) do
    local n = p:getMark("@@sa__blade")
    if n > 0 then
      local rec = p:getTableMark(MarkEnum.RevealProhibited)
      for _ = 1, n do
        table.removeOne(rec, "m")
        table.removeOne(rec, "d")
      end
      local flag = p:getMark("fengsui_jianan_reveal")
      if type(flag) == "string" and (flag == "m" or flag == "d")
          and not table.contains(rec, flag) then
        table.insert(rec, flag)
      end
      room:setPlayerMark(p, MarkEnum.RevealProhibited, #rec == 0 and 0 or rec)
      room:setPlayerMark(p, "@@sa__blade", 0)
    end
  end
end

local function applyCleanup(player, owned)
  if not player or not player.room then return end
  local room = player.room
  pcall(cleanupBladeResidual, room)
  if #owned == 0 then return end
  for _, name in ipairs(owned) do
    local entry = CLEANUP[name]
    local ok, err = pcall(function()
      clearMarks(room, player, entry.self_marks, false)
      clearMarks(room, player, entry.all_marks, true)
      if entry.extra then entry.extra(room, player) end
    end)
    if not ok then
      fk.qWarning("[fengsui-mark-cleanup] " .. name .. ": " .. tostring(err))
    end
  end
end

-- 亮将时 new_general 就是暗置前记下的武将名，不属于「变更」。
local function isReveal(player, new_general, isDeputy)
  local hidden = isDeputy and player:getMark("__heg_deputy") or player:getMark("__heg_general")
  return type(hidden) == "string" and hidden == new_general
end

-- 全局 Room 由 lua/server/scheduler.lua 设置；包 init 在客户端也会跑，
-- 那里可能拿不到，因此补一条 require 兜底并用 pcall 保护。
local function roomClass()
  if Room then return Room end
  local ok, cls = pcall(require, "ltk.server.room")
  if ok and type(cls) == "table" then return cls end
  return nil
end

local function installCleanupHooks()
  local R = roomClass()
  if R and R.changeHero and not R._fengsuiMarkCleanupChangeHero then
    local origChangeHero = R.changeHero
    R.changeHero = function(self, player, new_general, full, isDeputy, sendLog, maxHpChange, kingdomChange)
      local owned = (not isReveal(player, new_general, isDeputy)) and snapshot(player) or {}
      local ret = origChangeHero(self, player, new_general, full, isDeputy, sendLog, maxHpChange, kingdomChange)
      applyCleanup(player, owned)
      return ret
    end
    R._fengsuiMarkCleanupChangeHero = true
  end

  local RemoveGeneral = H.GameEvent and H.GameEvent.RemoveGeneral
  if RemoveGeneral and RemoveGeneral.main and not RemoveGeneral._fengsuiMarkCleanup then
    local origMain = RemoveGeneral.main
    RemoveGeneral.main = function(self)
      local player = self.data and self.data.who
      local owned = snapshot(player)
      local ret = origMain(self)
      applyCleanup(player, owned)
      return ret
    end
    RemoveGeneral._fengsuiMarkCleanup = true
  end
end

installCleanupHooks()

-- 目录按字母序 fengsui 早于 hegemony，init 阶段官方事件类可能尚未注册。
-- 每装完一个包重试一次，各包装自带幂等标记。
local Package = require "ltk.core.package"
if not Package._fengsuiMarkCleanupInstallHook then
  local origInstall = Package.install
  Package.install = function(self, engine)
    origInstall(self, engine)
    pcall(installCleanupHooks)
  end
  Package._fengsuiMarkCleanupInstallHook = true
end

return true
