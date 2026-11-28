-- The upstream hegemony package now bundles an older Fengsui package. Load
-- the official packages explicitly so the standalone current Fengsui package
-- is the only one registering Fengsui generals and cards.
local hegemonyPackages = require "packages/fengsui/pkg/hegemony_packages"

Fk:loadTranslationTable{
  ["fengsui"] = "烽燧燎原",
  ["fengsui_hebi"] = "烽燧燎原-合璧",
  ["fengsui_liwu"] = "烽燧燎原-离骛",
  ["fengsui_shiyi"] = "烽燧燎原-拾遗",
  ["fengsui_cards"] = "<font color='red'>烽燧燎原卡牌</font>",
  ["fengsui_mode"] = "<font color='green'>燎原之战</font>",
  ["fengsui_effect"] = "烽燧燎原-特效",
  ["fengsui_titles"] = "烽燧燎原-称号",
  ["fengsui_skins"] = "烽燧燎原-皮肤",
}

local __fengsui_compat = (function()
local H = require "packages.hegemony.util"
local FengsuiH = require "packages.fengsui.hegemony_util"

-- Keep the extended transform contract inside Fengsui so the official
-- hegemony package can remain untouched.
function H.transformGeneral(room, player, isMain, isHidden, num, skillName)
  return FengsuiH.transformGeneral(room, player, isMain, isHidden, num, skillName)
end

function H.wildChooseKingdom(player, generalName)
  local room = player.room
  local allChoices = table.clone(H.wildKingdoms)
  local choices = table.clone(allChoices)
  for _, p in ipairs(room.players) do
    table.removeOne(choices, p.role)
  end

  local choice
  if player.general == generalName and H.kingdomMapper[generalName] and
      H.kingdomMapper[generalName] ~= player.role and table.contains(choices, H.kingdomMapper[generalName]) then
    choice = H.kingdomMapper[generalName]
  else
    if #choices == 0 then choices = table.clone(allChoices) end
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = "game_rule",
      prompt = "#wild-choose",
      cancelable = false,
      all_choices = allChoices,
    })
  end

  player.role = choice
  room:setPlayerProperty(player, "role_shown", true)
  room:broadcastProperty(player, "role")
  room:sendLog{
    type = "#WildChooseKingdom",
    from = player.id,
    arg = choice,
    arg2 = "wild",
  }
  return choice
end

if not H._fengsuiOriginalInFormationRelation then
  H._fengsuiOriginalInFormationRelation = H.inFormationRelation
  H.inFormationRelation = function(player, target)
    if H._fengsuiOriginalInFormationRelation(player, target) then return true end
    local room = (player and player.room) or (target and target.room) or Fk:currentRoom()
    if not room or not player or not target or not H.compareKingdomWith(player, target) then return false end
    local ignoresRelation = player:getMark("@fengsui_heg__zhouwang-round") > 0 or
      target:getMark("@fengsui_heg__zhouwang-round") > 0 or table.find(room.alive_players, function(p)
      return p:hasSkill("fengsui_heg__chenji") and H.compareKingdomWith(p, player)
    end) ~= nil
    if not ignoresRelation then return false end
    if player ~= target then return true end
    return table.find(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player)
    end) ~= nil
  end
end

if not H._fengsuiOriginalInSiegeRelation then
  H._fengsuiOriginalInSiegeRelation = H.inSiegeRelation
  H.inSiegeRelation = function(player, target, victim)
    if H._fengsuiOriginalInSiegeRelation(player, target, victim) then return true end
    if not player or not target or not victim or victim == player or victim == target or
      victim.kingdom == "unknown" or H.compareKingdomWith(player, victim) or
      not H.compareKingdomWith(player, target) then return false end
    return table.find(player.room.alive_players, function(p)
      return p:hasSkill("fengsui_heg__chenji") and H.compareKingdomWith(p, player)
    end) ~= nil
  end
end

-- 戚举会把部分角色暂时置为“未确定势力”。官方阵法召唤技的
-- canUse 仍会用该势力去索引已确定势力人数表，得到 nil 后直接与
-- 人数比较，AI 在生成响应时就会报 “attempt to compare nil with number”。
-- 未确定势力本身不能发动这类阵法召唤技，因此在风随兼容层提前拒绝，
-- 不改动 packages/hegemony 的源文件。
if H.ArraySummonSkill and not H.ArraySummonSkill._fengsuiUnknownKingdomGuard then
  local originalArraySummonCanUse = H.ArraySummonSkill.canUse
  H.ArraySummonSkill.canUse = function(self, player, card)
    if not player or player.kingdom == "unknown" then return false end
    return originalArraySummonCanUse(self, player, card)
  end
  H.ArraySummonSkill._fengsuiUnknownKingdomGuard = true
end

-- 军巍临时获得“付授”时，官方实现会直接索引暗将名 anjiang，
-- 导致首亮或暗置过程中 getInvalidity/技能刷新报错。保留官方逻辑，
-- 但跳过当前仍为暗将的位置。
local fushou = Fk.skills and Fk.skills["heg__fushou"]
if fushou and not fushou._fengsuiSafeSync then
  local function sync(player, losing)
    local room = player and player.room
    if not room then return end
    local Heg = require "packages.hegemony.util"
    local targets = table.filter(room.alive_players, function(p)
      return Heg.compareKingdomWith(p, player)
    end)
    for _, p in ipairs(targets) do
      local main = p.general ~= "anjiang" and Fk.generals[p.general] or nil
      local deputy = p.deputyGeneral ~= "anjiang" and Fk.generals[p.deputyGeneral] or nil
      for _, g in ipairs({main, deputy}) do
        if g then
          for _, name in ipairs(g:getSkillNameList()) do
            local sk = Fk.skill_skels[name]
            local isDeputySkill = sk and sk:hasTag(Skill.DeputyPlace)
            local isMainSkill = sk and sk:hasTag(Skill.MainPlace)
            if (g == main and isDeputySkill) or (g == deputy and isMainSkill) then
              room:handleAddLoseSkills(p, losing and ("-" .. name) or name, nil, true, false)
            end
          end
        end
      end
    end
  end
  fushou.on_acquire = function(player) sync(player, false) end
  fushou.on_lose = function(player) sync(player, true) end
  fushou._fengsuiSafeSync = true
end

-- 允许风随技能给移除武将事件补充触发技能名，完整走官方的
-- GeneralRemoving/GeneralRemoved 特效链，同时保持旧的两参数调用兼容。
if H.removeGeneral and not H._fengsuiRemoveGeneralWithSkill then
  local originalRemoveGeneral = H.removeGeneral
  H.removeGeneral = function(player, isDeputy, skillName)
    fk.qWarning("[fengsui-remove] removeGeneral player=" .. tostring(player and player.id) ..
      " deputy=" .. tostring(isDeputy) .. " skillName=" .. tostring(skillName))
    if not skillName then return originalRemoveGeneral(player, isDeputy) end
    local data = H.GeneralRemoveData:new{ who = player, isDeputy = isDeputy or false, skillName = skillName }
    local event = H.GameEvent.RemoveGeneral:create(data)
    local _, ret = event:exec()
    return ret
  end
  H._fengsuiRemoveGeneralWithSkill = true
  fk.qWarning("[fengsui-remove] removeGeneral skillName wrapper installed")
elseif not H.removeGeneral then
  fk.qWarning("[fengsui-remove] H.removeGeneral nil, wrapper NOT installed")
end

if Room and not Room._fengsuiKnownBothWrapped then
  local originalAskToChoice = Room.askToChoice
  Room.askToChoice = function(self, player, params)
    local choice = originalAskToChoice(self, player, params)
    local capture = self._fengsuiKnownBothCapture
    if capture and player == capture.player and params.skill_name == "known_both" then
      capture.choice = choice
    end
    return choice
  end
  Room._fengsuiKnownBothWrapped = true
end

-- 麒麟弓等旧技能使用 card_data 选择牌时没有传 prompt；AI 的卡牌选择
-- 处理器会对 prompt 做字符串解析，因此必须补一个稳定的默认提示。
if Room and not Room._fengsuiChooseCardPromptWrapped then
  local originalAskToChooseCard = Room.askToChooseCard
  Room.askToChooseCard = function(self, player, params)
    if params and not params.prompt then params.prompt = "#fengsui-card-choose" end
    return originalAskToChooseCard(self, player, params)
  end
  Room._fengsuiChooseCardPromptWrapped = true
end

Fk:loadTranslationTable{
  ["#ChangeHiddenGeneral"] = "%from 变更了 %arg（暗置）",
  ["#fengsui-card-choose"] = "请选择一张牌",
}

return H
end)()

-- 注册「即将暗置武将牌」时机（fk.BeforeGeneralHidden）。事件类必须早于子包技能加载，
-- 方法包装由 lua/server/scheduler.lua 在 ServerPlayer 就绪后完成。
local __fengsui_before_hidden = (function()
-- 「即将暗置武将牌」时机。
--
-- 引擎只提供 fk.GeneralHidden：它由 ServerPlayer:hideGeneral 在整段暗置流程
-- 走完之后才触发（写 __heg_general/__heg_deputy、换成 anjiang、剥技能、重算
-- 性别、发日志都在它之前）。技能若挂在这个时机上再把人明置回来，暗置的
-- 副作用已经全部发生过一遍，等于空转。
--
-- 这里补一个 fk.BeforeGeneralHidden：包装 ServerPlayer.hideGeneral，在原函数
-- 之前触发，data = { is_deputy = boolean, prevented = boolean }。技能在 on_use
-- 里把 data.prevented 置 true 即可取消这次暗置（本文件不主动取消任何东西，
-- 默认暗置照常发生）。
--
-- 加载分两步：
--   1. 事件类必须在包加载前注册，技能 addEffect 时会引用到它；
--   2. 方法包装必须等 ServerPlayer 全局就绪，由 lua/server/scheduler.lua
--      在赋值后 pcall 调用 installPatch。
-- 两步都做成幂等，客户端（没有 ServerPlayer）只走第一步。

local M = {}

--- 注册事件类；TriggerEvent 尚不可用时返回 nil，调用方可重试。
function M.installEvent()
  if not fk.BeforeGeneralHidden and TriggerEvent then
    fk.BeforeGeneralHidden = TriggerEvent:subclass("fk.BeforeGeneralHidden")
  end
  return fk.BeforeGeneralHidden
end

--- 包装 ServerPlayer.hideGeneral；没有 ServerPlayer 时只保证事件类存在。
function M.installPatch()
  M.installEvent()
  if not ServerPlayer or not fk.BeforeGeneralHidden then
    return false
  end
  if ServerPlayer.__fengsui_before_hidden_patched then return true end

  local original = ServerPlayer.hideGeneral
  if type(original) ~= "function" then return false end

  ServerPlayer.hideGeneral = function(self, isDeputy)
    local room = self.room
    -- 不在对局中（房间搭建、测试 mock）时没有 logic，直接走原逻辑。
    if room and room.logic and not self.dead then
      local data = { is_deputy = isDeputy, prevented = false }
      room.logic:trigger(fk.BeforeGeneralHidden, self, data)
      if data.prevented then return false end
    end
    return original(self, isDeputy)
  end

  ServerPlayer.__fengsui_before_hidden_patched = true
  return true
end

M.installEvent()

return M
end)()
__fengsui_before_hidden.installEvent()

local fengsui_hebi = require "packages/fengsui/pkg/fengsui_hebi"

local fengsui_cards = require "packages/fengsui/pkg/fengsui_cards"
local fengsui_liwu = require "packages/fengsui/pkg/fengsui_liwu"
local fengsui_shiyi = require "packages/fengsui/pkg/fengsui_shiyi"
local fengsui_effect = require "packages/fengsui/pkg/fengsui_effect"
local fengsui_mode = require "packages/fengsui/pkg/fengsui_mode"
local fengsui_titles = require "packages/fengsui/pkg/fengsui_titles"
local fengsui_skins = require "packages/fengsui/pkg/fengsui_skins"

local __fengsui_audio_overlay = (function()
local overlayGenerals = {
  "ol_heg__caozhi",
  "heg__jiananfeng",
  "heg__simajiong",
  "heg__simawei",
  "heg__simayij",
  "heg__simaying",
  "heg__simayong",
  "heg__simayue",
  "heg__sunxiuj",
  "heg__yangjun",
}

local nineVariationsCards = {
  overbearing = true,
  part_ways = true,
  reveal_intention = true,
  tricky_heist = true,
  unworthy_continuation = true,
}

local function fengsuiPackageProxy(original)
  local proxy = {}
  for key, value in pairs(original) do
    proxy[key] = value
  end
  proxy.extensionName = "fengsui"
  proxy._fengsuiOriginalPackage = original
  setmetatable(proxy, getmetatable(original))
  return proxy
end

local function findGeneral(packages, name)
  if Fk.generals[name] then return Fk.generals[name] end
  for _, package in ipairs(packages or {}) do
    for _, general in ipairs(package.generals or {}) do
      if general.name == name then return general end
    end
  end
end

return function(packages, cardOverlayPackage)
  local applied = 0
  for _, name in ipairs(overlayGenerals) do
    local general = findGeneral(packages, name)
    if general and general.package and general.package.extensionName ~= "fengsui" then
      general.package = fengsuiPackageProxy(general.package)
      applied = applied + 1
    elseif general and general.package and general.package.extensionName == "fengsui" then
      applied = applied + 1
    end
  end

  assert(applied == #overlayGenerals, "fengsui audio overlay must bind all official hegemony generals")

  local cardSkels = {}
  for _, package in ipairs(packages or {}) do
    for index = #(package.card_skels or {}), 1, -1 do
      local skel = package.card_skels[index]
      if nineVariationsCards[skel.spec.name] then
        table.insert(cardSkels, skel)
        table.remove(package.card_skels, index)
      end
    end
  end

  assert(#cardSkels == 5, "fengsui audio overlay must bind all five Nine Variations cards")
  cardOverlayPackage:loadCardSkels(cardSkels)
end
end)()
__fengsui_audio_overlay(hegemonyPackages, fengsui_cards)
local __fengsui_runtime_trans = (function()
local function translated_skill_name(skill_name)
  local translated = Fk:translate(skill_name)
  if translated == skill_name then
    local base_name = skill_name:gsub("Remake%d*", "")
    translated = Fk:translate(base_name)
  end
  return translated == skill_name and "技能" or translated
end

local function skill_prompt(skill_name, action)
  return translated_skill_name(skill_name) .. "：" .. action
end

Fk:loadTranslationTable {
  ["fengsui_heg__aobiRemake"] = translated_skill_name("fengsui_heg__aobiRemake"),
  ["fengsui_heg__bizunRemake"] = translated_skill_name("fengsui_heg__bizunRemake"),
  ["fengsui_heg__chenmengRemake"] = translated_skill_name("fengsui_heg__chenmengRemake"),
  ["fengsui_heg__dishangRemake"] = translated_skill_name("fengsui_heg__dishangRemake"),
  ["fengsui_heg__fenshuangRemake"] = translated_skill_name("fengsui_heg__fenshuangRemake"),
  ["fengsui_heg__fudaoRemake"] = translated_skill_name("fengsui_heg__fudaoRemake"),
  ["fengsui_heg__fumianRemake"] = translated_skill_name("fengsui_heg__fumianRemake"),
  ["fengsui_heg__fumianRemake2"] = translated_skill_name("fengsui_heg__fumianRemake2"),
  ["fengsui_heg__fuzhuRemake"] = translated_skill_name("fengsui_heg__fuzhuRemake"),
  ["fengsui_heg__guishangRemake"] = translated_skill_name("fengsui_heg__guishangRemake"),
  ["fengsui_heg__hexiRemake"] = translated_skill_name("fengsui_heg__hexiRemake"),
  ["fengsui_heg__jiezhiRemake"] = translated_skill_name("fengsui_heg__jiezhiRemake"),
  ["@fengsui_heg__jiezhi-turn"] = "节枝",
  ["@fengsui_heg__jiezhi-turn1"] = "节枝",
  ["@fengsui_heg__jiezhi-turn2"] = "节枝",
  ["@fengsui_heg__jiezhi-turn3"] = "节枝",
  ["@fengsui_heg__qingsong-turn"] = "青松",
  ["@fengsui_heg__qingsong-turn1"] = "青松",
  ["@fengsui_heg__qingsong-turn2"] = "青松",
  ["fengsui_heg__jincaiRemake"] = translated_skill_name("fengsui_heg__jincaiRemake"),
  ["fengsui_heg__jiyuanRemake"] = translated_skill_name("fengsui_heg__jiyuanRemake"),
  ["fengsui_heg__juanzhiRemake"] = translated_skill_name("fengsui_heg__juanzhiRemake"),
  ["fengsui_heg__junweiRemake"] = translated_skill_name("fengsui_heg__junweiRemake"),
  ["fengsui_heg__liefaRemake"] = translated_skill_name("fengsui_heg__liefaRemake"),
  ["fengsui_heg__linzheRemake"] = translated_skill_name("fengsui_heg__linzheRemake"),
  ["fengsui_heg__xiangchenRemake"] = translated_skill_name("fengsui_heg__xiangchenRemake"),
  ["fengsui_heg__yingmenRemake"] = translated_skill_name("fengsui_heg__yingmenRemake"),
  ["fengsui_heg__qushengRemake"] = translated_skill_name("fengsui_heg__qushengRemake"),
  ["fengsui_heg__cangjuanRemake"] = translated_skill_name("fengsui_heg__cangjuanRemake"),
  ["fengsui_heg__chaohuaRemake"] = translated_skill_name("fengsui_heg__chaohuaRemake"),
  ["fengsui_heg__choutaoRemake"] = translated_skill_name("fengsui_heg__choutaoRemake"),
  ["fengsui_heg__chuguangRemake"] = translated_skill_name("fengsui_heg__chuguangRemake"),
  ["fengsui_heg__chuguangRemake2"] = translated_skill_name("fengsui_heg__chuguangRemake2"),
  ["fengsui_heg__dexiangRemake"] = translated_skill_name("fengsui_heg__dexiangRemake"),
  ["fengsui_heg__hejueRemake"] = translated_skill_name("fengsui_heg__hejueRemake"),
  ["fengsui_heg__hejueRemake2"] = translated_skill_name("fengsui_heg__hejueRemake2"),
  ["fengsui_heg__hexiRemake2"] = translated_skill_name("fengsui_heg__hexiRemake2"),
  ["fengsui_heg__hexiRemake3"] = translated_skill_name("fengsui_heg__hexiRemake3"),
  ["fengsui_heg__huaixiangRemake2"] = translated_skill_name("fengsui_heg__huaixiangRemake2"),
  ["fengsui_heg__jiaosuRemake"] = translated_skill_name("fengsui_heg__jiaosuRemake"),
  ["fengsui_heg__jincaiRemake2"] = translated_skill_name("fengsui_heg__jincaiRemake2"),
  ["fengsui_heg__jiuboRemake"] = translated_skill_name("fengsui_heg__jiuboRemake"),
  ["fengsui_heg__juanguRemake"] = translated_skill_name("fengsui_heg__juanguRemake"),
  ["fengsui_heg__kangyingRemake"] = translated_skill_name("fengsui_heg__kangyingRemake"),
  ["fengsui_heg__lianxiRemake"] = translated_skill_name("fengsui_heg__lianxiRemake"),
  ["fengsui_heg__lianxiRemake2"] = translated_skill_name("fengsui_heg__lianxiRemake2"),
  ["fengsui_heg__lianxiRemake3"] = translated_skill_name("fengsui_heg__lianxiRemake3"),
  ["fengsui_heg__niejiangRemake"] = translated_skill_name("fengsui_heg__niejiangRemake"),
  ["fengsui_heg__pijianRemake"] = translated_skill_name("fengsui_heg__pijianRemake"),
  ["fengsui_heg__qingshangRemake"] = translated_skill_name("fengsui_heg__qingshangRemake"),
  ["fengsui_heg__qujianRemake"] = translated_skill_name("fengsui_heg__qujianRemake"),
  ["fengsui_heg__shenqingRemake"] = translated_skill_name("fengsui_heg__shenqingRemake"),
  ["fengsui_heg__tongyiRemake"] = translated_skill_name("fengsui_heg__tongyiRemake"),
  ["fengsui_heg__tuanfengRemake"] = translated_skill_name("fengsui_heg__tuanfengRemake"),
  ["fengsui_heg__xiarongRemake"] = translated_skill_name("fengsui_heg__xiarongRemake"),
  ["fengsui_heg__xuanheRemake"] = translated_skill_name("fengsui_heg__xuanheRemake"),
  ["fengsui_heg__yaomingRemake"] = translated_skill_name("fengsui_heg__yaomingRemake"),
  ["fengsui_heg__yinbingRemake"] = translated_skill_name("fengsui_heg__yinbingRemake"),
  ["fengsui_heg__yinbingRemake2"] = translated_skill_name("fengsui_heg__yinbingRemake2"),
  ["fengsui_heg__yisangRemake2"] = translated_skill_name("fengsui_heg__yisangRemake2"),
  ["fengsui_heg__yuandaoRemake"] = translated_skill_name("fengsui_heg__yuandaoRemake"),
  ["fengsui_heg__yundaoRemake"] = translated_skill_name("fengsui_heg__yundaoRemake"),
  ["fengsui_heg__yunxingRemake"] = translated_skill_name("fengsui_heg__yunxingRemake"),
  ["fengsui_heg__anshiRemake"] = translated_skill_name("fengsui_heg__anshiRemake"),
  ["fengsui_heg__qingshi_jxRemake"] = translated_skill_name("fengsui_heg__qingshi_jxRemake"),
  ["fengsui_heg__shugeRemake"] = translated_skill_name("fengsui_heg__shugeRemake"),
  ["fengsui_heg__xiangkuiRemake"] = translated_skill_name("fengsui_heg__xiangkuiRemake"),
  ["fengsui_heg__yangmingRemake2"] = translated_skill_name("fengsui_heg__yangmingRemake2"),
  ["fengsui_heg__xuguRemake"] = "虚谷",
  ["fengsui_heg__xionglieRemake"] = "雄烈",
  ["fengsui_heg__qiangongRemake"] = translated_skill_name("fengsui_heg__qiangongRemake"),
  ["fengsui_heg__qiaosiRemake"] = translated_skill_name("fengsui_heg__qiaosiRemake"),
  ["fengsui_heg__qingsongRemake"] = translated_skill_name("fengsui_heg__qingsongRemake"),
  ["fengsui_heg__weihouRemake"] = translated_skill_name("fengsui_heg__weihouRemake"),
  ["fengsui_heg__weiluanRemake"] = translated_skill_name("fengsui_heg__weiluanRemake"),
  ["fengsui_heg__yanzuoRemake"] = translated_skill_name("fengsui_heg__yanzuoRemake"),
  ["fengsui_heg__yingmianRemake"] = translated_skill_name("fengsui_heg__yingmianRemake"),
  ["fengsui_heg__yisangRemake"] = translated_skill_name("fengsui_heg__yisangRemake"),
  ["fengsui_heg__zeyuRemake"] = translated_skill_name("fengsui_heg__zeyuRemake"),
  ["fengsui_heg__zhenchaoRemake"] = translated_skill_name("fengsui_heg__zhenchaoRemake"),
  ["fengsui_heg__zhengchiRemake"] = translated_skill_name("fengsui_heg__zhengchiRemake"),
  ["fengsui_heg__zhouwangRemake"] = translated_skill_name("fengsui_heg__zhouwangRemake"),

  ["#battle_royal&"] = "鏖战：请选择一名角色",
  ["#fengsui_heg__aobiRemake-choice"] = skill_prompt("fengsui_heg__aobiRemake", "请选择一项"),
  ["#fengsui_heg__bizunRemake-invoke"] = skill_prompt("fengsui_heg__bizunRemake", "你可以发动此技能"),
  ["#fengsui_heg__chenmengRemake"] = skill_prompt("fengsui_heg__chenmengRemake", "请选择一名角色"),
  ["#fengsui_heg__chenmengRemake-choice"] = skill_prompt("fengsui_heg__chenmengRemake", "请选择一项"),
  ["#fengsui_heg__chenmengRemake-discard"] = skill_prompt("fengsui_heg__chenmengRemake", "请选择要弃置的牌"),
  ["#fengsui_heg__chenmengRemake-exchange"] = skill_prompt("fengsui_heg__chenmengRemake", "请选择要交换的牌"),
  ["#fengsui_heg__chenmengRemake-mark"] = skill_prompt("fengsui_heg__chenmengRemake", "请选择要记录的牌"),
  ["#fengsui_heg__dishangRemake-counterpart"] = skill_prompt("fengsui_heg__dishangRemake", "请选择对应角色"),
  ["#fengsui_heg__dishangRemake-invoke"] = skill_prompt("fengsui_heg__dishangRemake", "你可以发动此技能"),
  ["#fengsui_heg__dishangRemake-invoke-victim"] = skill_prompt("fengsui_heg__dishangRemake", "你可以对受伤角色发动此技能"),
  ["#fengsui_heg__dishangRemake-slot"] = skill_prompt("fengsui_heg__dishangRemake", "请选择一个装备栏"),
  ["#fengsui_heg__fenshuangRemake-invoke"] = skill_prompt("fengsui_heg__fenshuangRemake", "你可以发动此技能"),
  ["#fengsui_heg__fudaoRemake-invoke"] = skill_prompt("fengsui_heg__fudaoRemake", "你可以发动此技能"),
  ["#fengsui_heg__fumianRemake-choice"] = skill_prompt("fengsui_heg__fumianRemake", "请选择一项"),
  ["#fengsui_heg__fumianRemake-use"] = skill_prompt("fengsui_heg__fumianRemake", "请选择要使用的牌"),
  ["#fengsui_heg__fuzhuRemake-choice"] = skill_prompt("fengsui_heg__fuzhuRemake", "请选择一项"),
  ["#fengsui_heg__fuzhuRemake-discard"] = skill_prompt("fengsui_heg__fuzhuRemake", "请选择要弃置的牌"),
  ["#fengsui_heg__fuzhuRemake-invoke"] = skill_prompt("fengsui_heg__fuzhuRemake", "你可以发动此技能"),
  ["#fengsui_heg__guishangRemake"] = skill_prompt("fengsui_heg__guishangRemake", "请选择一名角色"),
  ["#fengsui_heg__guishangRemake-choice"] = skill_prompt("fengsui_heg__guishangRemake", "请选择一项"),
  ["#fengsui_heg__hexiRemake-choice"] = skill_prompt("fengsui_heg__hexiRemake", "请选择一项"),
  ["#fengsui_heg__hexiRemake-choose"] = skill_prompt("fengsui_heg__hexiRemake", "请选择一名角色"),
  ["#fengsui_heg__jiezhiRemake-invoke"] = skill_prompt("fengsui_heg__jiezhiRemake", "你可以发动此技能"),
  ["#fengsui_heg__jincaiRemake-choice"] = skill_prompt("fengsui_heg__jincaiRemake", "请选择一项"),
  ["#fengsui_heg__jincaiRemake-choose"] = skill_prompt("fengsui_heg__jincaiRemake", "请选择一名角色"),
  ["#fengsui_heg__jiyuanRemake-choose"] = skill_prompt("fengsui_heg__jiyuanRemake", "请选择一名角色"),
  ["#fengsui_heg__jiyuanRemake-discard"] = skill_prompt("fengsui_heg__jiyuanRemake", "请选择要弃置的牌"),
  ["#fengsui_heg__juanzhiRemake-targets"] = skill_prompt("fengsui_heg__juanzhiRemake", "请选择目标角色"),
  ["#fengsui_heg__junweiRemake-choice"] = skill_prompt("fengsui_heg__junweiRemake", "请选择一项"),
  ["#fengsui_heg__junweiRemake-hide"] = skill_prompt("fengsui_heg__junweiRemake", "请选择要暗置的武将牌"),
  ["#fengsui_heg__junweiRemake-reveal"] = skill_prompt("fengsui_heg__junweiRemake", "请选择要明置的武将牌"),
  ["#fengsui_heg__liefaRemake-discard"] = skill_prompt("fengsui_heg__liefaRemake", "请选择要弃置的牌"),
  ["#fengsui_heg__liefaRemake-invoke"] = skill_prompt("fengsui_heg__liefaRemake", "你可以发动此技能"),
  ["#fengsui_heg__linzheRemake"] = skill_prompt("fengsui_heg__linzheRemake", "请选择一名角色"),
  ["#fengsui_heg__linzheRemake-choice"] = skill_prompt("fengsui_heg__linzheRemake", "请选择一项"),
  ["#fengsui_heg__linzheRemake-trick"] = skill_prompt("fengsui_heg__linzheRemake", "请选择一张普通锦囊牌"),
  ["#fengsui_heg__qiangongRemake-area"] = skill_prompt("fengsui_heg__qiangongRemake", "请选择一个区域"),
  ["#fengsui_heg__qiangongRemake-draw"] = skill_prompt("fengsui_heg__qiangongRemake", "请选择摸牌角色"),
  ["#fengsui_heg__qiangongRemake-invoke"] = skill_prompt("fengsui_heg__qiangongRemake", "你可以发动此技能"),
  ["#fengsui_heg__qiangongRemake-take"] = skill_prompt("fengsui_heg__qiangongRemake", "请选择要获得的牌"),
  ["#fengsui_heg__qiaosiRemake-choice"] = skill_prompt("fengsui_heg__qiaosiRemake", "请选择一项"),
  ["#fengsui_heg__qingsongRemake-to"] = skill_prompt("fengsui_heg__qingsongRemake", "请选择一名角色"),
  ["#fengsui_heg__qingsongRemake-use"] = skill_prompt("fengsui_heg__qingsongRemake", "请选择要使用的牌"),
  ["#fengsui_heg__weihouRemake-invoke"] = skill_prompt("fengsui_heg__weihouRemake", "你可以发动此技能"),
  ["#fengsui_heg__weiluanRemake-invoke"] = skill_prompt("fengsui_heg__weiluanRemake", "你可以发动此技能"),
  ["#fengsui_heg__weiluanRemake-top"] = skill_prompt("fengsui_heg__weiluanRemake", "请选择置于牌堆顶的牌"),
  ["#fengsui_heg__yanzuoRemake"] = skill_prompt("fengsui_heg__yanzuoRemake", "请选择一名角色"),
  ["#fengsui_heg__yanzuoRemake-name"] = skill_prompt("fengsui_heg__yanzuoRemake", "请选择一个牌名"),
  ["#fengsui_heg__yingmianRemake-ask"] = skill_prompt("fengsui_heg__yingmianRemake", "请选择是否响应"),
  ["#fengsui_heg__yisangRemake-choice"] = skill_prompt("fengsui_heg__yisangRemake", "请选择一项"),
  ["#fengsui_heg__yisangRemake-invoke"] = skill_prompt("fengsui_heg__yisangRemake", "你可以发动此技能"),
  ["#fengsui_heg__yisangRemake-replace"] = skill_prompt("fengsui_heg__yisangRemake", "请选择要替换的牌"),
  ["#fengsui_heg__zeyuRemake-choice"] = skill_prompt("fengsui_heg__zeyuRemake", "请选择一项"),
  ["#fengsui_heg__zeyuRemake-invoke"] = skill_prompt("fengsui_heg__zeyuRemake", "你可以发动此技能"),
  ["#fengsui_heg__zhengchiRemake-invoke"] = skill_prompt("fengsui_heg__zhengchiRemake", "你可以发动此技能"),
  ["#fengsui_heg__zhouwangRemake"] = skill_prompt("fengsui_heg__zhouwangRemake", "请选择一名角色"),

  ["@fengsui_heg__fumian"] = translated_skill_name("fengsui_heg__fumian"),
  ["@fengsui_heg__fumianRemake"] = translated_skill_name("fengsui_heg__fumianRemake"),
  ["@fengsui_heg__fumianRemake2"] = translated_skill_name("fengsui_heg__fumianRemake2"),
  ["@fengsui_heg__fuyin_bottom"] = translated_skill_name("fengsui_heg__fuyin") .. "（牌堆底）",
  ["@fengsui_heg__fuyin_top"] = translated_skill_name("fengsui_heg__fuyin") .. "（牌堆顶）",
  ["@fengsui_heg__guitu"] = translated_skill_name("fengsui_heg__guitu"),
  ["@fengsui_heg__huaixiang"] = translated_skill_name("fengsui_heg__huaixiang"),
  ["@fengsui_heg__jincai"] = translated_skill_name("fengsui_heg__jincai"),
  ["@fengsui_heg__junwei"] = translated_skill_name("fengsui_heg__junwei"),
  ["@fengsui_heg__junweiRemake"] = translated_skill_name("fengsui_heg__junweiRemake"),
  ["@fengsui_heg__ruluo"] = translated_skill_name("fengsui_heg__ruluo"),
  ["@fengsui_heg__zhouwang"] = translated_skill_name("fengsui_heg__zhouwang"),
  ["@fengsui_heg__zhouwangRemake"] = translated_skill_name("fengsui_heg__zhouwangRemake"),
  ["@fengsui_toaru__heg__tanghou"] = translated_skill_name("fengsui_toaru__heg__tanghou"),

  -- ===== Remake 描述与提示语补全 =====
  ["fengsui_heg__aobiRemake"] = "拗愎",
  [":fengsui_heg__aobiRemake"] = "锁定技，回合开始时你选择一项直到回合结束：1.你使用牌只能指定你为目标，且你使用牌结算结束后摸一张牌；2.你使用牌不能指定你为目标，且你于回合内使用每种花色的第一张牌额外结算一次。若你本回合未造成过伤害，回合结束时你失去1点体力。",
  ["fengsui_heg__bizunRemake"] = "迁宫",
  [":fengsui_heg__bizunRemake"] = "每回合限X次（X为与你势力相同的角色数），当一名与你势力相同的角色的手牌、装备区或判定区被移空后，你可以令其摸一张牌。",
  ["#fengsui_heg__bizunRemake-invoke"] = "迁宫：你可以令 %dest 摸一张牌",
  ["fengsui_heg__cangjuanRemake"] = "藏卷",
  [":fengsui_heg__cangjuanRemake"] = "每局限一次，当你明置武将牌后，你可以使用场上或牌堆中的一张【挟天子以令诸侯】，然后其拥有者摸一张牌；此后若场上没有「诏书」，你获得一张「诏书」并可使用之。每回合限一次，你可以将你的「诏」中的牌当同名牌使用或打出（无距离限制，且使用【杀】或【酒】以外牌时不计入次数），然后你将一张与此牌花色不同的手牌置于你的「诏」。",
  ["fengsui_heg__chaohuaRemake"] = "朝华",
  [":fengsui_heg__chaohuaRemake"] = "出牌阶段限一次，你可以选择一名武将牌均明置的其他角色的一张已明置武将牌，选择一项：1.将其以此牌于本轮发动过的技能的使用次数清零，然后暗置此武将牌且其本回合不能明置该武将牌；2.暗置此武将牌且其本回合不能明置该武将牌，若此牌为其主将牌，其限定技视为未发动过，然后其变更副将（每局限一次）。",
  ["fengsui_heg__chaohuaRemake_main"] = "主将牌",
  ["fengsui_heg__chaohuaRemake_deputy"] = "副将牌",
  ["fengsui_heg__chaohuaRemake_double"] = "重置本轮技能次数并暗置",
  ["fengsui_heg__chaohuaRemake_transform"] = "暗置并变更其副将",
  ["fengsui_heg__chenmengRemake"] = "谶梦",
  [":fengsui_heg__chenmengRemake"] = "与“谶梦”拥有者处于同一队列的角色于出牌阶段限一次，可以执行其中一项，另一项于此回合结束时执行：1.弃置至少两张牌，若弃置牌数等于你势力已明置的武将牌数，你获得一枚珠联璧合标记，否则你获得一枚阴阳鱼标记；2.使用你的一个标记并将一张手牌置于牌堆顶。",
  ["fengsui_heg__choutaoRemake"] = "仇讨",
  [":fengsui_heg__choutaoRemake"] = "其他角色的回合结束时，若你本回合获得过牌且手牌数大于其，你可以对其使用一张无距离限制的【杀】。",
  ["fengsui_heg__chuguangRemake"] = "黜光",
  [":fengsui_heg__chuguangRemake"] = "锁定技，当你于一轮内第X次发动“皎宿”或“曜暝”后（X为同势力角色数），你明置未明置的武将牌，然后暗置此技能所在的武将牌（本回合内不能明置），并令一名同势力角色摸X张牌。",
  ["#fengsui_heg__chuguangRemake-target"] = "黜光：请选择一名同势力角色摸牌",
  ["fengsui_heg__chuguangRemake2"] = "黜光",
  [":fengsui_heg__chuguangRemake2"] = "锁定技，当你于一轮内第X次发动“皎宿”或“曜暝”后（X为同势力角色数），“皎宿”与“曜暝”于本回合内失效，然后你令一名同势力角色摸X张牌；当成为过“皎宿”目标的角色脱离濒死状态后，你重置其武将牌并令其于本回合结束后执行一个额外的出牌阶段；当成为过“曜暝”目标的角色死亡后，你失去1点体力并暗置变更副将。",
  ["fengsui_heg__dexiangRemake"] = "德象",
  [":fengsui_heg__dexiangRemake"] = "当一名角色使用的基本牌或普通锦囊牌指定唯一目标后，你可以令一名与其距离1以内、武将牌均明置且与你势力相同的其他角色选择是否暗置一张武将牌成为此牌的目标。",
  ["#fengsui_heg__dexiangRemake-invoke"] = "德象：你可以暗置一张武将牌成为 %arg 的目标",
  ["fengsui_heg__dishangRemake"] = "抵殇",
  [":fengsui_heg__dishangRemake"] = "主将技，阵法技（围攻）。当伤害类牌指定目标后，此围攻关系中与你势力相同的角色可以弃置装备区里与对手围攻角色同栏位的一张装备牌（若其对手有多个则选择其一），然后此牌不可被响应。",
  ["#fengsui_heg__dishangRemake-invoke"] = "抵殇：你可以弃置装备牌使 %dest 不可响应",
  ["#fengsui_heg__dishangRemake-invoke-victim"] = "抵殇：你可以弃置装备牌使此牌对你不可响应",
  ["fengsui_heg__fenshuangRemake"] = "纷霜",
  [":fengsui_heg__fenshuangRemake"] = "出牌阶段限一次，你可以令攻击范围内的一名角色对你造成1点伤害，然后直到你的下回合开始，你发布的军令中不可被响应的对象转移给该角色。",
  ["#fengsui_heg__fenshuangRemake-invoke"] = "纷霜：请选择一名角色代你承受军令",
  ["fengsui_heg__fudaoRemake"] = "扶倒",
  [":fengsui_heg__fudaoRemake"] = "限定技，当你对一名角色造成伤害时，你可以弃置所有手牌，令此伤害+X（X为你本回合使用过的伤害类牌名数）；然后本回合进入弃牌堆的伤害类牌中，每张与你本回合使用过的牌名均不同的牌视为由目标对你使用。",
  ["fengsui_heg__fudaoRemake-invoke"] = "扶倒：你可以弃置所有手牌令对 %dest 的伤害+%arg",
  ["fengsui_heg__liefaRemake"] = "烈伐",
  [":fengsui_heg__liefaRemake"] = "每回合每项限一次，你可以视为使用一张【杀】、【闪】、【桃】或【酒】；若此牌目标包含你，你弃置至多两张牌，否则你失去1点体力，然后当前回合角色若与你势力相同，其摸一张牌。",
  ["fengsui_heg__fumianRemake"] = "福绵",
  [":fengsui_heg__fumianRemake"] = "出牌阶段开始时，你可以重铸至多X张牌（X为同势力已明置的武将牌数）；当你于本阶段使用的牌牌名字数等于X时，你于本阶段结束时可以视为使用之（无距离限制且不计入次数）或摸X张牌。",
  ["#fengsui_heg__fumianRemake-recast"] = "福绵：请选择要重铸的牌（至多 %arg 张）",
  ["fengsui_heg__guishangRemake"] = "诡赏",
  [":fengsui_heg__guishangRemake"] = "出牌阶段，你可以展示至少一张手牌并发布一条军令指定一名本回合未成为过目标的其他角色，该角色选择一项：1.获得这些牌并执行军令；2.弃置一张与其展示牌花色均不同的牌，视为使用【以逸待劳】。",
  ["#fengsui_heg__guishangRemake-discard"] = "诡赏：请选择一张与展示牌花色不同的牌弃置",
  ["fengsui_heg__guruRemake"] = "孤茹",
  [":fengsui_heg__guruRemake"] = "锁定技，当你仅明置一张武将牌后，你摸牌阶段额外摸X张牌（X为同势力角色数）；若你武将牌均明置且同势力角色数小于场上势力数，你与其他角色相互间的距离+X（X为同势力角色数）。",
  ["@fengsui_heg__guruRemake_distance"] = "距离",
  ["fengsui_heg__hejueRemake"] = "合珏",
  [":fengsui_heg__hejueRemake"] = "当你受到伤害后，你可以选择场上的一至两张武将牌：若选两张且构成珠联璧合，其所属角色各摸一张牌；若选一张，其所属角色选择合璧或变更副将。",
  ["#fengsui_heg__hejueRemake-invoke1"] = "合珏：你可以挑选场上武将牌",
  ["#fengsui_heg__hejueRemake-choose"] = "合珏：请选择场上的一至两张武将牌",
  ["#fengsui_heg__hejueRemake-choice"] = "合珏：请选择一项",
  ["fengsui_heg__hejueRemake2"] = "合珏",
  [":fengsui_heg__hejueRemake2"] = "当你受到伤害后，你可以选择场上的一至两张武将牌：若选两张且构成珠联璧合，其所属角色各摸一张牌；然后若所选牌属于同一名角色，其可以合璧或变更副将。",
  ["#fengsui_heg__hejueRemake2-invoke1"] = "合珏：你可以挑选场上武将牌",
  ["#fengsui_heg__hejueRemake2-choose"] = "合珏：请选择场上的一至两张武将牌",
  ["fengsui_heg__hexiRemake"] = "貉隙",
  [":fengsui_heg__hexiRemake"] = "你在摸牌阶段外获得牌后，你可以将自己装备区里的一张牌置入其他角色的装备区，该角色选择一项：1.若其武将牌未均明置，明置一张武将牌并摸两张牌；2.若其武将牌均明置，暗置一张武将牌，然后其对当前回合角色造成1点伤害。",
  ["#fengsui_heg__hexiRemake-move"] = "貉隙：请选择要移动的装备牌",
  ["fengsui_heg__hexiRemake2"] = "貉隙",
  [":fengsui_heg__hexiRemake2"] = "你在摸牌阶段外获得牌后，你可以将自己一张装备牌置入其他角色的装备区，该角色选择一项：1.若其武将牌未均明置，明置一张武将牌并对当前回合角色造成1点伤害；2.若其武将牌均明置，暗置一张武将牌并摸两张牌（本回合不能明置）。",
  ["fengsui_heg__hexiRemake3"] = "貉隙",
  [":fengsui_heg__hexiRemake3"] = "当你受到伤害后，你可以移动装备区里的一张牌，令一名其他角色选择一项：1.对当前回合角色造成1点伤害；2.暗置其一张武将牌且本回合无法明置。",
  ["#fengsui_heg__hexiRemake3-choice"] = "貉隙：请选择一项",
  ["fengsui_heg__huaixiangRemake2"] = "怀香",
  [":fengsui_heg__huaixiangRemake2"] = "与你势力相同的角色于出牌阶段内弃置或重铸牌进入弃牌堆后，你可以获得其中一张与其本阶段已进入弃牌堆类别均不相同类别的牌，并令一名角色获得与此牌类别对应的效果。",
  ["fengsui_heg__jiaosuRemake"] = "皎宿",
  [":fengsui_heg__jiaosuRemake"] = "主将技，当不同势力角色使用单体目标牌指定同势力角色为目标后，你可以主副将<a href='heg__yiwei'>易位</a>并取消之，然后该目标角色摸一张牌。",
  ["fengsui_heg__jiezhiRemake"] = "节枝",
  [":fengsui_heg__jiezhiRemake"] = "你的牌被其他角色获得后，若弃牌堆中有与其类别不同且你本回合未以此法获得的牌，你可以获得之：若其与你获得的牌颜色相同，其本回合不能对你使用牌；否则你本回合不能对其使用牌。",
  ["#fengsui_heg__jiezhiRemake-invoke"] = "节枝：你可以获得一张类别不同的弃牌",
  ["@fengsui_heg__jiezhiRemake-turn"] = "节枝",
  ["fengsui_heg__jincaiRemake"] = "矜才",
  [":fengsui_heg__jincaiRemake"] = "每轮限一次，当你使用红色基本牌或普通锦囊牌结算结束后，你可以令一名角色选择一项：1.摸两张牌并暗置一张武将牌，然后其对你造成的伤害-1；2.本回合不能使用红色牌。",
  ["fengsui_heg__jincaiRemake_draw"] = "摸两张牌并暗置一张武将牌",
  ["fengsui_heg__jincaiRemake_red"] = "本回合不能使用红色牌",
  ["#fengsui_heg__jincaiRemake-choose"] = "矜才：请选择一名角色",
  ["#fengsui_heg__jincaiRemake-choice"] = "矜才：请选择一项",
  ["fengsui_heg__jincaiRemake2"] = "矜才",
  [":fengsui_heg__jincaiRemake2"] = "每轮限一次，当你使用红色基本牌或普通锦囊牌结算结束后，你可以令一名角色选择一项：1.摸两张牌，若其武将牌均明置则暗置一张且本回合不能明置；2.本回合不能使用红色牌。",
  ["#fengsui_heg__jincaiRemake2-choose"] = "矜才：请选择一名角色",
  ["#fengsui_heg__jincaiRemake2-choice"] = "矜才：请选择一项",
  ["fengsui_heg__jincaiRemake2_draw"] = "摸两张牌",
  ["fengsui_heg__jincaiRemake2_red"] = "本回合不能使用红色牌",
  ["fengsui_heg__jiuboRemake"] = "救帛",
  [":fengsui_heg__jiuboRemake"] = "当与你势力相同的角色成为伤害类牌的唯一目标时，若其为此牌本回合的唯一目标且你武将牌均明置，你可以弃置一张非基本牌取消此目标；若使用者本回合首次使用牌，其转而以你为目标。",
  ["#fengsui_heg__jiuboRemake-invoke"] = "救帛：请选择要弃置的一张非基本牌",
  ["fengsui_heg__juanguRemake"] = "眷故",
  [":fengsui_heg__juanguRemake"] = "每回合每名角色限一次，当前回合角色使用基本牌或普通锦囊牌指定唯一目标后，若其与目标（的武将牌间）有珠联璧合关系，你可以选择一项：1.此牌额外结算一次；2.其与目标各摸一张牌。",
  ["#fengsui_heg__juanguRemake-invoke"] = "眷故：是否发动？",
  ["fengsui_heg__jiyuanRemake"] = "霁愿",
  [":fengsui_heg__jiyuanRemake"] = "限定技，当你进入濒死状态时，你可以令一名同势力角色将体力值回复至体力上限并将手牌摸至体力上限（多于则弃至体力上限），然后其暗置变更副将；当此濒死结算结束后，你移除此技能所在的武将牌。",
  ["#fengsui_heg__jiyuanRemake-choose"] = "霁愿：请选择一名同势力角色",
  ["#fengsui_heg__jiyuanRemake-discard"] = "霁愿：请弃置至 %arg 张手牌",
  ["fengsui_heg__juanzhiRemake"] = "卷帙",
  [":fengsui_heg__juanzhiRemake"] = "与你势力相同的角色的准备阶段开始时，你可以重铸一张牌，然后你于此回合使用与此牌类别相同的牌被指定为目标后，你可以为此牌增加至多X名合法目标（X为同势力角色数）。",
  ["#fengsui_heg__juanzhiRemake-recast"] = "卷帙：请选择要重铸的一张牌",
  ["#fengsui_heg__juanzhiRemake-targets"] = "卷帙：请选择至多 %arg 名合法目标",
  ["@fengsui_heg__juanzhiRemake-turn"] = "卷帙",
  ["fengsui_heg__junweiRemake"] = "军巍",
  [":fengsui_heg__junweiRemake"] = "阵法技（阵法）。与你处于同一队列的角色的回合开始时，其选择一项：1.暗置一张武将牌，获得其另一张武将牌上的所有技能直到你的下回合开始；2.明置一张或两张武将牌并获得等量的阴阳鱼标记。",
  ["fengsui_heg__kangyingRemake"] = "亢膺",
  [":fengsui_heg__kangyingRemake"] = "同势力角色受到伤害后，其可以与你交换副将，然后“组绨”拥有者的攻击范围于本回合内+1，且其对同势力角色造成伤害时于本回合首次伤害+1。",
  ["#fengsui_heg__kangyingRemake-invoke"] = "亢膺：你可以与 %src 交换副将",
  ["fengsui_heg__lianxiRemake"] = "连徙",
  [":fengsui_heg__lianxiRemake"] = "一名与你势力相同的角色的武将牌被暗置后（张白除外），你可以弃置其一个区域里的所有牌，对当前回合角色造成1点伤害，然后与一名同势力角色主副将易位。",
  ["#fengsui_heg__lianxiRemake-invoke"] = "连徙：是否发动？",
  ["#fengsui_heg__lianxiRemake-swap"] = "连徙：请选择一名同势力角色易位",
  ["fengsui_heg__lianxiRemake2"] = "连徙",
  [":fengsui_heg__lianxiRemake2"] = "一名与你势力相同的角色的武将牌被暗置后（张白除外），你可以弃置其一个区域里的所有牌，对当前回合角色造成1点伤害，然后与一名同势力角色主副将易位。",
  ["#fengsui_heg__lianxiRemake2-invoke"] = "连徙：是否发动？",
  ["#fengsui_heg__lianxiRemake2-swap"] = "连徙：请选择一名同势力角色易位",
  ["fengsui_heg__lianxiRemake3"] = "连徙",
  [":fengsui_heg__lianxiRemake3"] = "一名与你势力相同的角色的武将牌被暗置后（张白除外），你可以弃置其一个区域里的所有牌，令其可以对当前回合角色造成1点伤害，然后与一名同势力角色主副将易位。",
  ["#fengsui_heg__lianxiRemake3-invoke"] = "连徙：是否发动？",
  ["#fengsui_heg__lianxiRemake3-swap"] = "连徙：请选择一名同势力角色易位",
  ["fengsui_heg__linzheRemake"] = "遴哲",
  [":fengsui_heg__linzheRemake"] = "限定技，出牌阶段，你可以令所有同势力角色依次选择一项：1.使用一张手牌中的普通锦囊牌（无距离限制），然后变更副将；2.获得一枚标记（手牌数等于体力上限获得珠联璧合标记，否则获得阴阳鱼标记）。",
  ["fengsui_heg__niejiangRemake"] = "蹑江",
  [":fengsui_heg__niejiangRemake"] = "锁定技，体力值最低的角色每回合首次体力值变化后，你摸一张牌（每回合每名角色限一次）；你与其他体力值最低的角色的距离视为1。",
  ["fengsui_heg__pijianRemake"] = "辟剑",
  [":fengsui_heg__pijianRemake"] = "一名角色的结束阶段开始时，若你于本回合可以通过弃置手牌和装备区里的牌对应其进入弃牌堆的所有类别，你可以对应弃置之，然后对其造成1点雷电伤害。",
  ["#fengsui_heg__pijianRemake-card"] = "辟剑：请选择一张对应类别的牌弃置",
  ["fengsui_heg__qiangongRemake"] = "避尊",
  [":fengsui_heg__qiangongRemake"] = "出牌阶段限一次，你可以选择两名角色，若其间有均不为空的相同区域，你选择其中一个区域，令前者从后者该区域内获得一张牌。",
  ["#fengsui_heg__qiangongRemake-invoke"] = "避尊：请选择两名角色",
  ["#fengsui_heg__qiangongRemake-area"] = "避尊：请选择一个区域",
  ["fengsui_heg__qiaosiRemake"] = "峭嗣",
  [":fengsui_heg__qiaosiRemake"] = "结束阶段开始时，若你本回合弃置过牌且仍在弃牌堆，你可以选择一种类别获得其中一张，若获得张数不等于你的体力值，你失去1点体力。",
  ["#fengsui_heg__qiaosiRemake-choice"] = "峭嗣：请选择要获得的牌的类别",
  ["fengsui_heg__qingshangRemake"] = "清殇",
  [":fengsui_heg__qingshangRemake"] = "锁定技，每局限一次，当你受到伤害时，若伤害来源不是你且伤害值不小于你的体力值与护甲之和，你防止此伤害，然后若“曹叁”为你的副将则变更副将，否则移除“曹叁”，且伤害来源视为对你使用一张冰【杀】。",
  ["fengsui_heg__qingsongRemake"] = "青松",
  [":fengsui_heg__qingsongRemake"] = "当你成为牌的目标后，若你武将牌均明置，你可以将一张与此牌类别不同的手牌交给一名其他角色并暗置你的另一张武将牌；若其与你势力不同，本回合结束时你可以使用与之牌名相同的一张牌。",
  ["#fengsui_heg__qingsongRemake-give"] = "青松：请选择一张与此牌类别不同的手牌",
  ["#fengsui_heg__qingsongRemake-to"] = "青松：请选择一名角色",
  ["#fengsui_heg__qingsongRemake-use"] = "青松：你可以使用一张同名牌",
  ["@fengsui_heg__qingsongRemake-turn"] = "青松",
  ["fengsui_heg__qujianRemake"] = "祛僭",
  [":fengsui_heg__qujianRemake"] = "准备阶段开始时，你可以选择至多X名角色（X为同势力角色数）令其各摸一张牌，然后若其中手牌数最少与最多的角色均唯一且不同，手牌最少者视为对手牌最多者使用一张雷【杀】；之后你可以与其中一名角色拼点，拼点赢的角色令输的角色处于连环状态。",
  ["#fengsui_heg__qujian-choose"] = "祛僭：请选择至多 %arg 名角色",
  ["#fengsui_heg__qujian-pindian"] = "祛僭：请选择一名拼点对象",
  ["fengsui_heg__shenqingRemake"] = "申情",
  [":fengsui_heg__shenqingRemake"] = "限定技，出牌阶段，你可以选择场上两张武将牌，若其构成珠联璧合，其所属角色各获得一枚珠联璧合标记；否则你可以令其中一位所属角色<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__tongyiRemake"] = "通意",
  [":fengsui_heg__tongyiRemake"] = "当你受到伤害进入濒死状态时，若你武将牌均明置且伤害来源不为空手牌，你可以暗置此武将牌，亮出牌堆顶的一张牌并展示伤害来源的一张手牌：若两者颜色相同，你回复1点体力；然后将牌堆顶的牌置于牌堆顶。",
  ["#fengsui_heg__tongyiRemake-invoke"] = "通意：你可以暗置此武将牌并亮出牌堆顶与 %dest 的一张手牌",
  ["#fengsui_heg__tongyiRemake-show"] = "通意：请选择 %dest 的一张手牌亮出",
  ["fengsui_heg__tuanfengRemake"] = "抟风",
  [":fengsui_heg__tuanfengRemake"] = "准备阶段开始时，你可以重铸一张牌，然后本回合内与你势力相同的角色使用与此牌类别相同的牌时无次数和距离限制（每名角色每回合每类别限一次）。",
  ["#fengsui_heg__tuanfengRemake-recast"] = "抟风：请选择要重铸的一张牌",
  ["@fengsui_heg__tuanfengRemake-round"] = "抟风",
  ["fengsui_heg__tuanfengRemake3"] = "抟风",
  [":fengsui_heg__tuanfengRemake3"] = "当你受到伤害后，若你武将牌均明置，你可以获得弃牌堆中每种花色各一张牌；当你对其他角色造成伤害后，你可以令当前回合角色本回合手牌上限+2。",
  ["#fengsui_heg__tuanfengRemake3-invoke"] = "抟风：你可以获得弃牌堆中每种花色各一张牌",
  ["#fengsui_heg__tuanfengRemake3-handlimit"] = "抟风：你可以令 %src 本回合手牌上限+2",
  ["fengsui_heg__weihouRemake"] = "维后",
  [":fengsui_heg__weihouRemake"] = "与你势力相同的角色的判定牌生效前，若你武将牌均明置，你可以用装备区里的一张牌代替判定牌，然后暗置此技能所在的武将牌；若代替牌与原判定牌颜色相同，该角色于判定结束后可以合璧或变更副将。",
  ["#fengsui_heg__weihouRemake-invoke"] = "维后：请选择要代替判定的一张牌",
  ["fengsui_heg__weiluanRemake"] = "危鸾",
  [":fengsui_heg__weiluanRemake"] = "同势力角色成为伤害类牌的目标后，若其武将牌均明置，你可以暗置其一张武将牌，其摸一张牌并将一张手牌置于牌堆顶。",
  ["#fengsui_heg__weiluanRemake-invoke"] = "危鸾：是否发动？",
  ["#fengsui_heg__weiluanRemake-top"] = "危鸾：请选择一张手牌置于牌堆顶",
  ["fengsui_heg__xiarongRemake"] = "遐容",
  [":fengsui_heg__xiarongRemake"] = "与你势力相同的其他角色受到伤害后，若你们武将牌均明置，你可以暗置此技能所在的武将牌，其选择暗置自己的一张武将牌，然后其回复1点体力；若伤害来源不在你们任意一人的攻击范围内，你重新明置此武将牌。",
  ["fengsui_heg__xiarongRemake_main"] = "暗置主将",
  ["fengsui_heg__xiarongRemake_deputy"] = "暗置副将",
  ["fengsui_heg__xiarongRemake_main"] = "暗置主将",
  ["fengsui_heg__xiarongRemake_deputy"] = "暗置副将",
  ["fengsui_heg__xionglieRemake"] = "雄烈",
  [":fengsui_heg__xionglieRemake"] = "锁定技，你于每回合内使用的第一张牌指定武将牌未均明置的角色为目标后，此牌不可被响应；当你于每回合首次造成伤害时，若目标为女性角色，此伤害+1。",
  ["fengsui_heg__xuanheRemake"] = "悬河",
  [":fengsui_heg__xuanheRemake"] = "锁定技，每回合限一次，你使用牌结算结束后，此牌的目标角色于本回合内不能使用或打出与此牌类别相同的牌，其使用其他类别的牌后此限制失效；与你势力相同的角色不能使用你本回合未使用过其类别的牌指定你为目标。",
  ["fengsui_heg__xuguRemake"] = "虚谷",
  [":fengsui_heg__xuguRemake"] = "出牌阶段限一次，你可以发布一条军令并指定任意名角色，这些角色依次选择一项：1.执行军令；2.展示一张手牌并暗置所有武将牌。若选择执行军令的角色数不少于展示牌的角色数，你可以使用其中一张展示牌；否则每名执行军令的角色对其距离最近的展示牌角色（并列时自选）造成1点伤害。",
  ["#fengsui_heg__xuguRemake"] = "虚谷：请选择目标并发布一条军令",
  ["#fengsui_heg__xuguRemake-choice"] = "虚谷：请选择一项",
  ["#fengsui_heg__xuguRemake-show"] = "虚谷：请展示一张手牌",
  ["#fengsui_heg__xuguRemake-use"] = "虚谷：请使用其中一张展示牌",
  ["#fengsui_heg__xuguRemake-damage"] = "虚谷：请选择一名角色",
  ["xugu_do_command"] = "执行军令",
  ["xugu_show_hide"] = "展示一张手牌并暗置所有武将牌",
  ["fengsui_heg__yanzuoRemake"] = "研作",
  [":fengsui_heg__yanzuoRemake"] = "出牌阶段限一次，你可以重铸至少两张类别相同的手牌，然后你可以将其中等量张牌的合计视为此类别的任意一张牌使用（须选择等量目标，无距离和次数限制）。",
  ["#fengsui_heg__yanzuoRemake"] = "研作：请选择至少两张类别相同的牌",
  ["#fengsui_heg__yanzuoRemake-name"] = "研作：请选择要使用的牌与目标（%arg 名）",
  ["fengsui_heg__yaomingRemake"] = "曜暝",
  [":fengsui_heg__yaomingRemake"] = "副将技，同势力角色使用单体目标牌指定不同势力角色为目标后，你可以为此牌增加一名合法目标，然后主副将<a href='heg__yiwei'>易位</a>，使用者摸一张牌。",
  ["fengsui_heg__yinbingRemake"] = "饮冰",
  [":fengsui_heg__yinbingRemake"] = "锁定技，每轮限一次，你受到伤害后或你造成伤害后，受伤角色视为对伤害来源使用一张【冰】【杀】；若此【杀】未造成伤害，其摸两张牌并失去1点体力。",
  ["fengsui_heg__yinbingRemake2"] = "饮冰",
  [":fengsui_heg__yinbingRemake2"] = "主将技，锁定技，若你是唯一的大势力角色，与你势力相同的角色使用的牌不能被你响应；若你是小势力角色，你对大势力角色使用的牌不能被其响应。",
  ["fengsui_heg__yingmianRemake"] = "盈面",
  [":fengsui_heg__yingmianRemake"] = "当你受到伤害后，若你武将牌均明置，你可以暗置一张武将牌并发布一条军令指定一名角色：若军令被执行，执行者摸两张牌；否则你获得其一张牌。",
  ["#fengsui_heg__yingmianRemake-ask"] = "盈面：请选择一名角色",
  ["fengsui_heg__yisangRemake"] = "诒桑",
  [":fengsui_heg__yisangRemake"] = "你于回合内使用与上一张颜色相同的牌指定同势力角色为目标后，你可以亮出牌堆顶的一张牌，其选择一项：1.获得之；2.将一张牌置于牌堆顶，然后获得之。",
  ["#fengsui_heg__yisangRemake-invoke"] = "诒桑：是否发动？",
  ["#fengsui_heg__yisangRemake-choice"] = "诒桑：请选择一项",
  ["#fengsui_heg__yisangRemake-replace"] = "诒桑：请选择一张牌置于牌堆顶",
  ["fengsui_heg__yisangRemake2"] = "诒桑",
  [":fengsui_heg__yisangRemake2"] = "你于回合内使用与上一张颜色相同的牌指定同势力角色为目标后，你可以亮出牌堆顶的一张牌，其选择一项：1.获得之；2.将一张牌置于牌堆顶，然后获得之。",
  ["#fengsui_heg__yisangRemake2-invoke"] = "诒桑：是否发动？",
  ["#fengsui_heg__yisangRemake2-choice"] = "诒桑：请选择一项",
  ["#fengsui_heg__yisangRemake2-replace"] = "诒桑：请选择一张牌置于牌堆顶",
  ["fengsui_heg__yisangRemake2_get"] = "获得此牌",
  ["fengsui_heg__yisangRemake2_replace"] = "选择一张牌替换此牌",
  ["fengsui_heg__yuandaoRemake"] = "渊道",
  [":fengsui_heg__yuandaoRemake"] = "阵法技（阵法）。与你处于同一队列的角色于出牌阶段内使用普通锦囊牌结算结束后，其于此回合内使用的下一张普通锦囊牌不计入次数。",
  ["fengsui_heg__yundaoRemake"] = "熨道",
  [":fengsui_heg__yundaoRemake"] = "你与同势力角色互相造成伤害后：你可以令其合璧或变更副将；若你或其没有阴阳鱼标记，你可以令其中没有阴阳鱼标记的角色获得一枚阴阳鱼标记。",
  ["#fengsui_heg__yundaoRemake-change"] = "熨道：是否发动？",
  ["#fengsui_heg__yundaoRemake-fish"] = "熨道：请选择一名角色获得阴阳鱼标记",
  ["fengsui_heg__yunxingRemake"] = "陨星",
  [":fengsui_heg__yunxingRemake"] = "锁定技，你的准备阶段开始时和结束阶段开始时，你摸一张牌并将一张手牌置于牌堆顶；你的判定牌生效后，若判定点数小于同势力角色体力值之和，判定牌花色视为红桃，否则视为黑桃。",
  ["#fengsui_heg__yunxingRemake-top"] = "陨星：请选择一张手牌置于牌堆顶",
  ["fengsui_heg__zeyuRemake"] = "泽誉",
  [":fengsui_heg__zeyuRemake"] = "当一名与你势力相同的角色杀死一名与其势力不同的角色后，你可以令其摸两张牌并选择一项：1.主副将易位；2.变更副将。",
  ["#fengsui_heg__zeyuRemake-invoke"] = "泽誉：是否发动？",
  ["#fengsui_heg__zeyuRemake-choice"] = "泽誉：请选择一项",
  ["fengsui_heg__zeyuRemake_swap"] = "主副将易位",
  ["fengsui_heg__zeyuRemake_transform"] = "变更副将",
  ["fengsui_heg__zhengchiRemake"] = "正斥",
  [":fengsui_heg__zhengchiRemake"] = "每轮限一次，你使用牌指定同势力角色为目标后，你可以选择另一名角色与其拼点：拼点输的角色成为此牌的目标；若拼点牌点数均小于6，使用者改为拼点赢的角色。",
  ["#fengsui_heg__zhengchiRemake-invoke"] = "正斥：请选择一名角色拼点",
  ["#fengsui_heg__zhengchiRemake-target"] = "%from 让 %to 成为 %arg 的目标",
  ["#fengsui_heg__zhengchiRemake-user"] = "%from 改为由 %arg 的使用者",
  ["fengsui_heg__zhouwangRemake"] = "骤望",
  [":fengsui_heg__zhouwangRemake"] = "副将技，出牌阶段限一次，你可以移去X枚阴阳鱼标记（X为同势力已明置的武将牌数），将手牌摸至4张并视为对一名其他角色使用【知己知彼】；若其手牌中有重名的牌，你获得一枚于本回合内有效的骤望标记。",
  ["#fengsui_heg__zhouwangRemake"] = "骤望：请选择一名其他角色",
  ["fengsui_heg__anshiRemake"] = "谙世",
  [":fengsui_heg__anshiRemake"] = "准备阶段开始时，你可以视为对一名角色使用【知己知彼】，然后其选择一项：1.明置一张武将牌，你移除此技能并获得一个额外回合；2.将其手牌摸至或弃至手牌上限。",
  ["fengsui_heg__qingshi_jxRemake"] = "清饰",
  [":fengsui_heg__qingshi_jxRemake"] = "每轮限一次，当你成为黑色【杀】或黑色锦囊牌的目标后，你可以弃置一张黑色手牌取消此目标并获得此牌。",
  ["fengsui_heg__shugeRemake"] = "束阁",
  [":fengsui_heg__shugeRemake"] = "每轮限一次，当你受到伤害后，你可以展示一张伤害类手牌并将其交给一名角色（不能是伤害来源），然后其与伤害来源拼点：若拼点牌中有你展示的牌，以其拼点的角色受到1点雷电伤害；拼点赢的角色视为对输的角色使用一张同名牌。",
  ["#fengsui_heg__shugeRemake-give"] = "束阁：请选择一名角色和一张伤害类手牌",
  ["fengsui_heg__xiangkuiRemake"] = "飨馈",
  [":fengsui_heg__xiangkuiRemake"] = "其他同势力角色的回合开始时，其可以选择一种类别，然后你将至多X张与此类别不同的手牌交给其并摸等量张牌（X为同势力角色数）。",
  ["#fengsui_heg__xiangkuiRemake-invoke"] = "飨馈：你可以选择一种类别，令 %src 交给你其余类别的牌",
  ["#fengsui_heg__xiangkuiRemake-give"] = "飨馈：请选择要交给 %dest 的牌",
  ["fengsui_heg__yangmingRemake2"] = "扬名",
  [":fengsui_heg__yangmingRemake2"] = "与你势力相同的角色的回合结束时，若你于本回合内弃置或使用过至少两个类别的牌，你可以摸等量于类别数的牌。",
  ["fengsui_heg__yingmenRemake"] = "盈门",
  [":fengsui_heg__yingmenRemake"] = "锁定技，当你首次明置此武将牌后，你将X张势力各不相同且不为中立者或野心家的武将牌置于你的武将牌上，称为“访客”。回合开始时或你受到伤害后，若你的“访客”数少于X张，则你将“访客”补至X张（X为场上势力数）。",
  ["fengsui_heg__pingjianRemake"] = "评鉴",
  [":fengsui_heg__pingjianRemake"] = "当你发动“访客”提供的技能结算结束后，你移去提供此技能的访客并返还其武将牌：若其与你势力相同，你摸两张牌，否则你摸一张牌。",
  ["#fengsui_heg__pingjianRemake-remove"] = "评鉴：请选择提供此技能的访客",

  ["fengsui_heg__fuyinRemake"] = "负胤",
  [":fengsui_heg__fuyinRemake"] = "准备阶段开始时，你可以令所有其他同势力角色各选择将其一张牌置于牌堆顶或牌堆底；结束阶段开始时，比较你本回合造成的伤害点数与你本回合弃置的牌数：若伤害较多，置于牌堆顶的角色各摸两张牌，置于牌堆底的角色各失去1点体力；若弃牌较多，反之。",
  ["#fengsui_heg__fuyinRemake-invoke"] = "负胤：是否发动？",
  ["fengsui_heg__jietuRemake"] = "捷途",
  [":fengsui_heg__jietuRemake"] = "阵法技，出牌阶段限一次，你与同一队列的所有角色各重铸一张牌：其中重铸装备牌的角色摸一张牌，且于其下一个出牌阶段内使用【杀】的次数+1。",
  ["#fengsui_heg__jietuRemake-active"] = "捷途：请选择要发动",
  ["#fengsui_heg__jietuRemake-recast"] = "捷途：请选择要重铸的一张牌",
  ["@fengsui_heg__liusuRemake2_unknown-turn"] = "流愫",

  -- 2026-11-12 改版存档：断衿/连徙/申情/毓尘/告返 的改版前原文（序号递归）
  ["fengsui_heg__duanjinRemake"] = "断衿",
  [":fengsui_heg__duanjinRemake"] = "当此武将牌被移除或变更后，你可以与一名同势力其他角色副将<a href='heg__yiwei'>易位</a>并各获得一枚珠联璧合标记。",
  -- 2026-11-13 改版存档：改版前为「重铸装备区所有牌并令你与一名其他同势力角色各获得一枚」
  ["fengsui_heg__duanjinRemake2"] = "断衿",
  [":fengsui_heg__duanjinRemake2"] = "当你的武将牌被移除或变更后，你可以重铸装备区所有牌并令你与一名其他同势力角色各获得一枚珠联璧合标记。",
  -- 2026-11-13 改版存档：迁宫改版前为「令其中小势力角色摸一张牌，同势力可令其合璧」
  ["fengsui_heg__bizunRemake2"] = "迁宫",
  [":fengsui_heg__bizunRemake2"] = "出牌阶段限一次，你可以选择两名角色并选择一个二者均有牌的相同区域，所选角色依次获得彼此相同区域的一张牌，然后你可以令其中的小势力角色摸一张牌，若其与你势力相同，你可令其<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__lianxiRemake4"] = "连徙",
  [":fengsui_heg__lianxiRemake4"] = "锁定技，与你势力相同的角色明置武将牌数变化后，你令其选择一项：1.弃置一个区域所有牌并对当前回合角色造成一点伤害；2.摸两张牌并与你副将<a href='heg__yiwei'>易位</a>。",
  ["fengsui_heg__shenqingRemake2"] = "申情",
  [":fengsui_heg__shenqingRemake2"] = "出牌阶段限一次，你可以选择场上至多两名同势力角色，然后选择一项：1.令其中一名角色<a href='heg__hebi'>合璧</a>；2.令两名角色副将<a href='heg__yiwei'>易位</a>。",
  ["fengsui_heg__yuchenRemake2"] = "毓尘",
  [":fengsui_heg__yuchenRemake2"] = "出牌阶段限一次，你可以与一名其他同势力角色副将<a href='heg__yiwei'>易位</a>，易位前后控制此武将牌的角色中主副将阴阳鱼相等的角色依次（由你开始）选择一项：1.将手牌数摸至手牌上限；2.变更副将并获得一枚珠联璧合标记，然后移除此选项。",
  ["fengsui_heg__gaofanRemake"] = "告返",
  [":fengsui_heg__gaofanRemake"] = "当你需要响应其他同势力角色的一张牌或其他同势力角色需要响应你的一张牌时，你可以与其副将<a href='heg__yiwei'>易位</a>视为响应之，然后被响应方变更副将或对响应方造成1点伤害。",
  ["fengsui_heg__gaofanRemake_response&"] = "告返",
  [":fengsui_heg__gaofanRemake_response&"] = "你可以与贾褒副将易位，视为响应此牌。",
  ["#fengsui_heg__gaofanRemake-response"] = "告返：与贾褒副将易位，视为响应此牌",
  ["#fengsui_heg__gaofanRemake-choice"] = "告返：请选择变更副将，或对 %dest 造成1点伤害",
  ["fengsui_heg__gaofanRemake_transform"] = "变更副将",
  ["fengsui_heg__gaofanRemake_damage"] = "对响应方造成1点伤害",

  -- 2026-11-14 改版存档：合璧/变更副将由「令其执行」改为「令其选择是否执行」
  ["fengsui_heg__qiaoshiRemake"] = "樵拾",
  [":fengsui_heg__qiaoshiRemake"] = "当有角色受到属性伤害后，你可以与其各摸一张牌，若为同势力角色，你可令其<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__yundaoRemake2"] = "熨道",
  [":fengsui_heg__yundaoRemake2"] = "当你受到或造成属性伤害后，若伤害来源与你势力相同，你可令其<a href='heg__hebi'>合璧</a>；若受伤角色与你势力相同，你可令其发动一次“<a href=':hs__xunxun'>恂恂</a>”并获得牌堆底两张牌。",
  ["fengsui_heg__bizunRemake3"] = "迁宫",
  [":fengsui_heg__bizunRemake3"] = "出牌阶段限一次，你可以选择两名角色并选择一个二者均有牌的相同区域，所选角色依次获得彼此相同区域的一张牌，若其中对应区域牌较多角色与你势力相同且唯一，你可以令其<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__hejueRemake3"] = "合珏",
  [":fengsui_heg__hejueRemake3"] = "当你受到伤害后，你可以选择至多两名角色，若其中有两张珠联璧合的武将牌，则其对应角色各摸一张牌，否则你选择其中一名同势力角色<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__menyinRemake"] = "门荫",
  [":fengsui_heg__menyinRemake"] = "主将技，限定技，此武将牌上阴阳鱼数量-1。出牌阶段开始时，若你所在势力为大势力，你可以令一名武将牌均明置的同势力角色<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__ranlvRemake"] = "燃缕",
  [":fengsui_heg__ranlvRemake"] = "当有角色受到锦囊牌造成的伤害后，若你的武将牌均明置，你可以暗置此武将牌并横置你与受伤角色，若你已横置，你可以令一名势力与你相同的角色<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__shenqingRemake3"] = "申情",
  [":fengsui_heg__shenqingRemake3"] = "当你受到伤害后或出牌阶段开始时，你可以令一名同势力角色<a href='heg__hebi'>合璧</a>或摸X张牌（X为场上珠联璧合标记数）。",
  ["fengsui_heg__zeyuRemake2"] = "泽誉",
  [":fengsui_heg__zeyuRemake2"] = "主将技，当与你势力相同的角色因杀死其他角色而执行奖惩后，你可令其变更副将。",
  ["fengsui_heg__liefaRemake2"] = "烈伐",
  [":fengsui_heg__liefaRemake2"] = "阵法技，若你构成阵列：与你处于同一阵列的角色获得“冰心”；若你构成围攻，你获得“鸟翔”；若你均构成或均不构成，同势力角色明置武将牌后，你可以令其变更一次副将。",
  ["fengsui_heg__xunyunRemake2"] = "勋殒",
  [":fengsui_heg__xunyunRemake2"] = "<b>锁定技，</b>当你首次进入濒死状态时，你令伤害来源移除副将，然后令一名其他同势力角色<a href='heg__hebi'>合璧</a>。",

  -- 2026-11-14 矜才改版存档：成为目标后令使用者二选一（暗置否则此牌无效 / 令你获得此牌）
  ["fengsui_heg__jincaiRemake3"] = "矜才",
  [":fengsui_heg__jincaiRemake3"] = "每回合限一次，当你成为一张红色基本牌或普通锦囊牌的目标后，你可以令使用者选择一项：1.若其武将牌均明置，其需暗置一张武将牌且本回合无法明置，否则此牌对你无效；2.令你获得此牌。",
}

return true
end)()
local __fengsui_overrides = (function()
-- 风燧对官方技能的运行时兼容覆盖。
-- 这里不改 packages/hegemony 的源文件；仅替换触发条件/刷新分支等。
--
-- 关键机制说明：
-- 1. 扩展包的技能/武将并不是在 require 包文件时注册的——包文件只创建
--    Package 对象和骨架（SkillSkeleton），真正编译注册进 Fk.skills /
--    Fk.generals 发生在 ModManager:loadPackages 调用 Package:install 时
--    （ltk/core/package.lua: skel:createSkill() -> engine:addSkills）。
-- 2. 本文件在 fengsui 包 init 阶段执行，而目录按字母序 fengsui 早于
--    hegemony——此时官方技能尚未注册，Fk.skills.sijian 等全是 nil。
--    因此所有覆盖都挂在 Package.install 钩子上：每装完一个包就重试一轮，
--    各覆盖自带幂等标记，重复执行无副作用。
-- 3. ltk/core/skill_skeleton.lua 的 createTriggerSkill：
--    - 单效果技能经 addEffect 编译后，Fk.skills[name] 本身就是主效果对象，
--      related_skills 为空——收集效果对象时必须把主技能本身算进去；
--    - spec.can_trigger 在创建时被捕获进 triggerable 闭包（tmp_func），
--      运行期改 effect.can_trigger 字段无效；必须替换 triggerable；
--      同理 spec.on_refresh 装配为 refresh 字段，改 on_refresh 无效。

local Package = require "ltk.core.package"

--- 收集一个官方技能全部已编译的触发效果对象（去重）。
local function collectTriggerEffects(name)
  local seen, out = {}, {}
  local function add(e)
    if type(e) == "table" and e.event and not seen[e] then
      seen[e] = true
      table.insert(out, e)
    end
  end
  local main = Fk.skills and Fk.skills[name]
  if not main then return out end
  add(main)
  local skel = Fk.skill_skels and Fk.skill_skels[name]
  if skel then
    for _, e in ipairs(skel.effects or {}) do add(e) end
  end
  for _, e in ipairs(main.related_skills or {}) do add(e) end
  return out
end

local function overrideSijian()
  for _, effect in ipairs(collectTriggerEffects("sijian")) do
    if effect.event == fk.AfterCardsMove and not effect.__fengsui_sijian_override then
      -- 官方 can_trigger 把“若你没有手牌”写成了 not isKongcheng（条件写反），
      -- 导致仍有手牌时也能拆牌；该函数已被捕获进 triggerable 闭包，
      -- 因此这里整体替换 triggerable，不委托旧实现。
      effect.triggerable = function(_self, event, target, player, data)
        if not player or not player:hasSkill("sijian") or not player:isKongcheng() then
          return false
        end
        for _, move in ipairs(data) do
          if move.from == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                return table.find(player.room:getOtherPlayers(player, false), function(p)
                  return not p:isNude()
                end) ~= nil
              end
            end
          end
        end
        return false
      end
      effect.__fengsui_sijian_override = true
      fk.qInfo("[fengsui-overrides] sijian(死谏) triggerable 已替换")
    end
  end
end

-- 官方麒麟弓在传入 card_data 选择框时漏传 prompt，AI 会在解析空提示词时崩溃。
-- 仅补充该技能的默认提示，不改官方技能逻辑。
local function overrideKylinBowPrompt()
  if not Room or not Room.askToChooseCard or Room._fengsuiKylinBowPrompt then return end
  local original = Room.askToChooseCard
  Room.askToChooseCard = function(self, player, params)
    if params and not params.prompt and params.skill_name == "#kylin_bow_skill" then
      params.prompt = "#fengsui-kylin-bow"
    end
    return original(self, player, params)
  end
  Room._fengsuiKylinBowPrompt = true
  Fk:loadTranslationTable {
    ["#fengsui-kylin-bow"] = "麒麟弓：选择一张坐骑牌弃置",
  }
end

-- 官方卞夫人两个版本（nos_heg__bianfuren / ld__bianfuren）漏设女性性别，仅 ol 版正确。
local function overrideBianfurenGender()
  for _, name in ipairs({ "nos_heg__bianfuren", "ld__bianfuren" }) do
    local g = Fk.generals and Fk.generals[name]
    if g and g.gender ~= General.Female then
      g.gender = General.Female
      fk.qInfo("[fengsui-overrides] " .. name .. " 性别已改为女性")
    end
  end
end

-- 官方陆抗〖恪守〗(ld__keshou) 回合开始刷新时读错标记名（写成 @keshou，
-- 实际标记为 @ld__keshou），导致“下回合受到的伤害-1”永不生效。这里替换刷新分支。
-- 注意：spec.on_refresh 装配为效果对象的 refresh 字段，必须替换 refresh。
local function overrideLukangKeshou()
  for _, effect in ipairs(collectTriggerEffects("ld__keshou")) do
    if effect.event == fk.TurnStart and not effect.__fengsui_keshou_override then
      effect.refresh = function(_self, event, target, player, data)
        local room = player.room
        for _, p in ipairs(room.alive_players) do
          if p:getMark("@ld__keshou") > 0 then
            room:setPlayerMark(p, "@ld__keshou-turn", p:getMark("@ld__keshou"))
            room:setPlayerMark(p, "@ld__keshou", 0)
          end
        end
      end
      effect.__fengsui_keshou_override = true
      fk.qInfo("[fengsui-overrides] ld__keshou(恪守) refresh 已替换")
    end
  end
end

-- 官方小乔〖天香〗(hs__tianxiang) 在国战（hegemony）里的四处问题：
-- 1. can_trigger 只判 not isKongcheng，不判是否真有♥手牌（红颜转化后♠按♥计），
--    也不判选项是否为空；
-- 2. on_cost 的选牌 pattern 写死 "heart"，红颜把♠当♥时选不出牌；
-- 3. on_use 把 cost 里的牌表直接当单张牌 id 传给 getCardArea，永远取不到区域，
--    「目标获得你弃置的牌」这一项实际不生效；
-- 4. 失去体力分支本回合已用、且伤害来源已死时，选项为空，askToChoice 拿空表。
-- 这里整体替换 cost/use，不委托旧实现，避免半修。
local function tianxiangHeartCards(player)
  return table.filter(player:getCardIds("h"), function(id)
    local suit = Fk:getCardById(id):getSuitString()
    return suit == "heart" or (suit == "spade" and player:hasSkill("hs__hongyan"))
  end)
end

local function tianxiangChoices(player, data)
  local choices = {}
  if player:getMark("hs__tianxiang_loseHp-turn") == 0 then
    table.insert(choices, "hs__tianxiang_loseHp")
  end
  if data and data.from and not data.from.dead and player:getMark("hs__tianxiang_damage-turn") == 0 then
    table.insert(choices, "hs__tianxiang_damage")
  end
  return choices
end

local function overrideTianxiang()
  for _, effect in ipairs(collectTriggerEffects("hs__tianxiang")) do
    if effect.event == fk.DetermineDamageInflicted and not effect.__fengsui_tianxiang_override then
      -- spec.can_trigger 已被捕获进 triggerable 闭包，包裹 triggerable 才有效。
      local old_triggerable = effect.triggerable
      effect.triggerable = function(_self, event, target, player, data)
        if not player or target ~= player or not player:hasSkill("hs__tianxiang") then return false end
        if not player.room or not player.room.alive_players then return false end
        if #tianxiangHeartCards(player) == 0 then return false end
        local others = table.filter(player.room:getOtherPlayers(player, false), function(p)
          return p and not p.dead
        end)
        if #others == 0 then return false end
        if #tianxiangChoices(player, data) == 0 then return false end
        if old_triggerable then
          return old_triggerable(_self, event, target, player, data)
        end
        return true
      end

      effect.cost = function(self, event, target, player, data)
        local room = player.room
        local hearts = tianxiangHeartCards(player)
        local others = table.filter(room:getOtherPlayers(player, false), function(p)
          return p and not p.dead
        end)
        if #hearts == 0 or #others == 0 or #tianxiangChoices(player, data) == 0 then
          return false
        end
        -- pattern 用 id 表，红颜转化出的♠手牌才选得到。
        local to, card, ok = room:askToChooseCardsAndPlayers(player, {
          min_card_num = 1,
          max_card_num = 1,
          pattern = tostring(Exppattern{ id = hearts }),
          targets = others,
          min_num = 1,
          max_num = 1,
          cancelable = true,
          prompt = "#hs__tianxiang-choose",
          skill_name = "hs__tianxiang",
          will_throw = true,
          skip = true,
        })
        if not ok or type(to) ~= "table" or #to == 0 or type(card) ~= "table" or #card == 0 then
          return false
        end
        event:setCostData(self, { tos = to, cards = card })
        return true
      end

      effect.use = function(self, event, target, player, data)
        local room = player.room
        local costData = event:getCostData(self) or {}
        local to = (costData.tos or {})[1]
        local cid = (costData.cards or {})[1]
        if not to or to.dead or not cid then return end
        local choices = tianxiangChoices(player, data)
        if #choices == 0 then return end

        room:throwCard({ cid }, "hs__tianxiang", player, player)
        data:preventDamage()

        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = "hs__tianxiang",
          prompt = "#hs__tianxiang-choice::" .. to.id,
        })
        if choice == "hs__tianxiang_loseHp" then
          room:setPlayerMark(player, "hs__tianxiang_loseHp-turn", 1)
          room:loseHp(to, 1, "hs__tianxiang")
          local area = room:getCardArea(cid)
          if not to.dead and (area == Card.DrawPile or area == Card.DiscardPile) then
            room:obtainCard(to, cid, true, fk.ReasonJustMove)
          end
        else
          room:setPlayerMark(player, "hs__tianxiang_damage-turn", 1)
          room:damage{
            from = data.from,
            to = to,
            damage = 1,
            skillName = "hs__tianxiang",
          }
          if not to.dead then
            to:drawCards(math.min(to:getLostHp(), 5), "hs__tianxiang")
          end
        end
      end

      effect.__fengsui_tianxiang_override = true
      fk.qInfo("[fengsui-overrides] hs__tianxiang(天香) cost/use 已整体替换")
    end
  end
end

-- 官方十周年国战华歆〖息兵〗(ty_heg__xibing) 的暗置分支要求「你与其均明置了
-- 所有武将牌」，但触发条件 can_trigger 完全不判明置——只要对方本回合首次用
-- 黑色杀/锦囊指定唯一目标就能发动摸牌。fengsui 的约定是：息兵整个技能的触发
-- 时机就是「双方武将牌均明置」；任一方双将只亮了一张（getGeneralsRevealedNum
-- 未达满）就不触发。这里按 overrideTianxiang 的方式包裹 triggerable，
-- 不改官方源文件。
local function overrideXibing()
  local HegUtil = require "packages.hegemony.util"
  for _, effect in ipairs(collectTriggerEffects("ty_heg__xibing")) do
    if effect.event == fk.TargetSpecified and not effect.__fengsui_xibing_override then
      local old_triggerable = effect.triggerable
      effect.triggerable = function(_self, event, target, player, data)
        if not old_triggerable or not old_triggerable(_self, event, target, player, data) then
          return false
        end
        -- player 是息兵持有者（华歆），target 是被指定牌的角色（摸牌对象）。
        -- 双方都必须明置了所有武将牌；双将只亮一张则 allGeneralsRevealed 为假。
        if not HegUtil.allGeneralsRevealed(player) then return false end
        if not target or not target:isAlive() or not HegUtil.allGeneralsRevealed(target) then
          return false
        end
        return true
      end
      effect.__fengsui_xibing_override = true
      fk.qInfo("[fengsui-overrides] ty_heg__xibing(息兵) 加双方全明置触发门禁")
    end
  end
end

-- 官方裸衣的 @@hs__luoyi 没有 -turn 后缀，on_use 用 addPlayerMark 累加，
-- 而伤害效果按 getMark 取值，逐回合发动会叠成 +2/+3。这里在每次发动前
-- 先把标记归零，保持「此伤害+1」；换将后的清 0 由 mark_cleanup 负责。
local function fixLuoyiStacking()
  for _, effect in ipairs(collectTriggerEffects("hs__luoyi")) do
    if effect.event == fk.EventPhaseEnd and effect.use and not effect.__fengsui_luoyi_reset then
      local oldUse = effect.use
      effect.use = function(self, event, target, player, data)
        player.room:setPlayerMark(player, "@@hs__luoyi", 0)
        return oldUse(self, event, target, player, data)
      end
      effect.__fengsui_luoyi_reset = true
      fk.qInfo("[fengsui-overrides] hs__luoyi(裸衣) 发动前重置标记")
    end
  end
end

-- 官方建安把「不能明置」写成无后缀 RevealProhibited 里的一个 "m"/"d"，
-- 与青龙刀写的 "m"/"d" 完全同形，任何一边整表清零都会误伤另一边。
-- 这里在建安发动时把它自己加的那一项记到 fengsui_jianan_reveal；
-- 官方回合开始/死亡 refresh 会无条件清空全场该 mark，包装后补回
-- 仍在生效的青龙刀层数，并清掉这条记录。
local function trackJiananReveal()
  for _, effect in ipairs(collectTriggerEffects("jianan")) do
    if effect.use and not effect.__fengsui_jianan_reveal_use then
      local oldUse = effect.use
      effect.use = function(self, event, target, player, data)
        local before = target and target:getTableMark(MarkEnum.RevealProhibited) or {}
        local ret = oldUse(self, event, target, player, data)
        if target and target.room then
          local after = target:getTableMark(MarkEnum.RevealProhibited)
          if #after > #before then
            local added = after[#after]
            if added == "m" or added == "d" then
              target.room:setPlayerMark(target, "fengsui_jianan_reveal", added)
            end
          end
        end
        return ret
      end
      effect.__fengsui_jianan_reveal_use = true
    end

    if (effect.event == fk.TurnStart or effect.event == fk.Death) and
        effect.refresh and not effect.__fengsui_jianan_reveal_refresh then
      local oldRefresh = effect.refresh
      effect.refresh = function(self, event, target, player, data)
        local ret = oldRefresh(self, event, target, player, data)
        local room = player and player.room
        if room then
          for _, p in ipairs(room.players) do
            local n = p:getMark("@@sa__blade")
            if n > 0 then
              local rec = {}
              for _ = 1, n do
                table.insert(rec, "m")
                table.insert(rec, "d")
              end
              room:setPlayerMark(p, MarkEnum.RevealProhibited, rec)
            end
            room:setPlayerMark(p, "fengsui_jianan_reveal", 0)
          end
        end
        return ret
      end
      effect.__fengsui_jianan_reveal_refresh = true
    end
  end
end

-- 这些技能只负责悼离的阶段清理/特效，不应在战报中生成“【】”或
-- “【悼离骤雨】”。部分旧引擎版本不会把骨架上的 mute 完整复制到
-- 延迟触发器，因此在所有扩展技能实例创建后再强制静默一次。
local function muteDaoliSkills()
  for name, skill in pairs(Fk.skills or {}) do
    if name == "#fengsui_effect_daoli_rain" or
        name:startsWith("#fengsui_heg__daoli_") then
      skill.mute = true
      skill.audio_index = 0
      skill.no_indicate = true
    end
  end
end

-- 旧版存档技能（名字含 Remake）不挂载任何武将，只留作版本回溯。但其中很多
-- 带 global = true，引擎会把它们全部注册进 Fk.global_trigger；只要自身的
-- can_trigger 条件成立，就会对「根本没有这个技能」的玩家触发，弹出凭空出现的
-- 技能名询问框（例如碧玉用现版取声时，旧版 qushengRemake 会跟着弹出同名询问框）。
-- 这里统一补一道自身技能归属门控：不拥有该技能的玩家一律不触发、不刷新。
-- 若以后某处把旧版技能动态挂给武将，hasSkill 为真，技能照常可用。
local function guardArchiveSkills()
  for name in pairs(Fk.skills or {}) do
    if name:startsWith("fengsui_") and name:find("Remake", 1, true) then
      for _, effect in ipairs(collectTriggerEffects(name)) do
        if not effect.__fengsui_archive_guard then
          local oldTriggerable = effect.triggerable
          if oldTriggerable then
            effect.triggerable = function(_self, event, target, player, data)
              if not player or not player:hasSkill(name) then return false end
              return oldTriggerable(_self, event, target, player, data)
            end
          end
          local oldCanRefresh = effect.canRefresh
          if oldCanRefresh then
            effect.canRefresh = function(_self, event, target, player, data)
              if not player or not player:hasSkill(name) then return false end
              return oldCanRefresh(_self, event, target, player, data)
            end
          end
          effect.__fengsui_archive_guard = true
        end
      end
    end
  end
end

-- 官方司马冏〖独夫〗的描述是「摸牌阶段多摸两张牌」，但
-- jin_zfxp/skills/dufu.lua 的 DrawNCards 分支只写了 data.n + 1。
-- 保留官方实现，在其后补足第二张；不修改官方包源文件。
local function fixDufuDraw()
  for _, effect in ipairs(collectTriggerEffects("heg__dufu")) do
    if effect.event == fk.DrawNCards and type(rawget(effect, "use")) == "function" and
      not effect.__fengsui_dufu_draw_fix then
      local origUse = effect.use
      effect.use = function(self, event, target, player, data)
        origUse(self, event, target, player, data)
        data.n = data.n + 1
      end
      effect.__fengsui_dufu_draw_fix = true
      fk.qInfo("[fengsui-overrides] heg__dufu(独夫) 摸牌阶段补足两张")
    end
  end
end

-- 官方 ld__qice 的 onUse 直接拿 interaction.data 去 cloneCard。AI 或「使用牌」
-- 请求提交时可能不带 interaction_data，服务端会把它写成 nil，于是触发
-- "Attempt to clone a card that not added to engine: name=nil"。这里在 onUse
-- 前按当前手牌补一个合法锦囊牌名，不改官方技能文件。
local function guardQiceInteraction()
  local skill = Fk.skills and Fk.skills["ld__qice"]
  if not skill or skill.__fengsui_qice_guard or type(skill.onUse) ~= "function" then return end
  local origOnUse = skill.onUse
  skill.onUse = function(self, room, effect)
    local holder = self.interaction
    if holder and effect and effect.from then
      local name = holder.data
      if not name or not Fk.all_card_types[name] then
        local ok, spec = pcall(function() return self:interaction(effect.from) end)
        local fallback
        if ok and type(spec) == "table" then
          fallback = spec.default or (type(spec.choices) == "table" and spec.choices[1]) or nil
        end
        if fallback and Fk.all_card_types[fallback] then
          holder.data = fallback
        else
          fk.qWarning("[fengsui-overrides] ld__qice 无可用锦囊牌名，跳过本次发动")
          return
        end
      end
    end
    return origOnUse(self, room, effect)
  end
  skill.__fengsui_qice_guard = true
  fk.qInfo("[fengsui-overrides] ld__qice 已补 interaction 兜底")
end

-- 官方 ServerPlayerBase:doNotify 遍历 _observers / room.observers 时直接调
-- p:getState()、p:doNotify()。死亡结算、托管或视角切换期间控制者可能临时不是
-- 网络层 Player，C++ 绑定会抛 "expected player got 'serverplayer'"，整条通知链
-- 随之中断。这里在包加载时整体替换该方法（与 overrideSijian 同样的覆盖方式），
-- 不改官方源文件。lua/core/mod_manager.lua:35 把 ServerPlayerBase 赋成了全局，
-- 因此这里能直接取到类；install 钩子会重复调用，用标记保证只包装一次。
local function guardDoNotify()
  local cls = _G.ServerPlayerBase
  if type(cls) ~= "table" or cls._fengsuiDoNotifyGuard then return end
  if type(cls.doNotify) ~= "function" then return end

  cls.doNotify = function(self, command, data)
    -- 新版核心在 doNotify 前置做聊天过滤；旧版没有 filterChatMessage 就跳过。
    if command == "Chat" and type(data) == "table" and data.msg and
      type(cls.filterChatMessage) == "function" then
      local filtered = cls.filterChatMessage(data.msg)
      if not filtered then return end
      data.msg = filtered
    end

    local cbordata = cbor.encode(data)
    local room = self.room

    local function safeState(p)
      local ok, state = pcall(function() return p:getState() end)
      return ok and state or fk.Player_Robot
    end
    local function safeNotify(p)
      pcall(function() p:doNotify(command, cbordata) end)
    end

    for _, p in ipairs(self._observers) do
      if safeState(p) ~= fk.Player_Robot then
        room.notify_count = room.notify_count + 1
        safeNotify(p)
      end
    end

    for _, t in ipairs(room.observers) do
      local id, p = table.unpack(t)
      -- Reconnect 是整房序列化摘要，只应发给重连者本人做全量重建；
      -- 绑定它的旁观者若收到会把自己当重连者重建，打断观察视角。
      local ok, observing = pcall(function() return room.room:hasObserver(p) end)
      if id == self.id and command ~= "Reconnect" and ok and observing
        and safeState(p) ~= fk.Player_Robot then
        safeNotify(p)
      end
    end

    if room.notify_count >= room.notify_max and
      coroutine.status(room.main_co) == "normal" then
      room:delay(100)
    end
  end

  cls._fengsuiDoNotifyGuard = true
  fk.qInfo("[fengsui-overrides] ServerPlayerBase:doNotify 已加类型安全兜底")
end

-- 九变篇【分道扬镳】(part_ways) 在燎原之战(fengsui_heg__mode)里使用后不成为野心家：
-- 官方 onEffect 用 room:isGameMode("heg_mode") 判分支，燎原的 main_mode 正是 heg_mode，
-- 于是走 H.wildChooseKingdom 只改了 role（选国），却没有把 kingdom 置 wild、也没打
-- __heg_wild 标记；fengsui 全靠 __heg_wild 认定野心家（胜负/拉拢/副将规则都读它），
-- 所以角色看起来选了国却不是野心家。这里保留官方摸牌/给牌/选国逻辑，仅在其后补齐
-- fengsui 的野心家状态，与 _fengsui_neutral_rule.promoteWarlord 的写法一致。
-- 注意：cardskill 经 addEffect 编译后是独立技能 #part_ways_skill_1_cardskill，
-- spec.on_effect 装配为 onEffect 字段（skill_skeleton.lua:createCardSkill）。
local function overridePartWays()
  local sk = Fk.skills and Fk.skills["#part_ways_skill_1_cardskill"]
  if not sk or type(sk.onEffect) ~= "function" or sk.__fengsui_partways_override then return end
  local origOnEffect = sk.onEffect
  sk.onEffect = function(self, room, effect)
    local player = effect and effect.from
    origOnEffect(self, room, effect)
    if not player or player.dead then return end
    if room:getSettings("gameMode") ~= "fengsui_heg__mode" then return end
    if (tonumber(player:getMark("__heg_wild")) or 0) > 0 and player.kingdom == "wild" then return end
    room:setPlayerMark(player, "__heg_wild", 1)
    room:setPlayerProperty(player, "kingdom", "wild")
    fk.qInfo("[fengsui-overrides] part_ways(分道扬镳) 已补齐野心家状态")
  end
  sk.__fengsui_partways_override = true
  fk.qInfo("[fengsui-overrides] part_ways(分道扬镳) onEffect 已包装")
end

-- 官方野心家贾南风的〖放恣〗(heg__fangzi) 变更副将时调用
-- H.transformGeneral(room, player, false, true)，第4个参数 isHidden=true，
-- 于是变更出来的副将被暗置。fengsui 的规则是明置变更副将，这里在 use
-- 执行期间临时把 H.transformGeneral 的第4参改成 false，执行完立即还原，
-- 不影响其他技能的暗置变更（如落石）。
local function overrideFangziReveal()
  local HegUtil = require "packages.hegemony.util"
  if type(HegUtil.transformGeneral) ~= "function" then return end
  for _, effect in ipairs(collectTriggerEffects("heg__fangzi")) do
    if effect.event == fk.EventPhaseStart and effect.use and
      not effect.__fengsui_fangzi_reveal then
      local origUse = effect.use
      effect.use = function(self, event, target, player, data)
        local origTransform = HegUtil.transformGeneral
        HegUtil.transformGeneral = function(room, p, isMain, isHidden, ...)
          return origTransform(room, p, isMain, false, ...)
        end
        local ok, ret = pcall(origUse, self, event, target, player, data)
        HegUtil.transformGeneral = origTransform
        if not ok then error(ret) end
        return ret
      end
      effect.__fengsui_fangzi_reveal = true
      fk.qInfo("[fengsui-overrides] heg__fangzi(放恣) 变更副将改为明置")
    end
  end
end

-- 官方鏖战把〖赋礼〗(battle_royal_fuli) 作为六选一随机事件，其摸牌前的
-- askToSkillInvoke 选项框已由官方实现。fengsui 的规则是把这个事件从
-- all_events 随机池删除，效果并入「开启九变篇」开关：开启后每名角色摸牌
-- 阶段前都能勾选跳过并拿奇珍牌，未开启则整段效果不存在。
-- 这里做两件事：①事件抽取只要抽到赋礼就改抽其余五个事件之一；
-- ②赋礼效果的 triggerable 不再看当前事件，改看九变篇开关。
local function gateFuliEvent()
  local sk = Fk.skills and Fk.skills["#new_battle_royal_event&"]
  if not sk then return end
  local FALLBACK_EVENTS = {
    "battle_royal_bujinzetui", "battle_royal_luoshi",
    "battle_royal_shengzheweiwang", "battle_royal_huoqi", "battle_royal_jili",
  }
  for _, effect in ipairs(collectTriggerEffects("#new_battle_royal_event&")) do
    -- ① 事件抽取：赋礼已从事件池移除，抽到就同步换掉横幅、日志与已用记录
    if effect.event == fk.RoundStart and type(effect.trigger) == "function" and
      not effect.__fengsui_fuli_gate then
      local origTrigger = effect.trigger
      effect.trigger = function(self, event, target, player, data)
        origTrigger(self, event, target, player, data)
        local room = player.room
        if room:getBanner("@[:]new_battle_royal_event") ~= "battle_royal_fuli" then return end
        local used = room:getBanner("@[:]battle_royal_used_event") or {}
        local pool = {}
        for _, e in ipairs(FALLBACK_EVENTS) do
          if not table.contains(used, e) then table.insert(pool, e) end
        end
        if #pool == 0 then
          used = {}
          pool = table.simpleClone(FALLBACK_EVENTS)
        end
        local newEvent = room:tableRandomPick(pool)
        for i = #used, 1, -1 do
          if used[i] == "battle_royal_fuli" then table.remove(used, i) end
        end
        if not table.contains(used, newEvent) then table.insert(used, newEvent) end
        room:setBanner("@[:]new_battle_royal_event", newEvent)
        room:setBanner("@[:]battle_royal_used_event", used)
        room:sendLog{
          type = "new_battle_royal_event-log", arg = newEvent,
          arg2 = ":" .. newEvent, toast = true,
        }
        if newEvent == "battle_royal_luoshi" then
          local HegUtil = require "packages.hegemony.util"
          for _, p in ipairs(room:getAlivePlayers(true)) do
            if not p.dead and p.kingdom ~= "unknown" then
              HegUtil.transformGeneral(room, p, false, false, 1)
            end
          end
        end
        fk.qInfo("[fengsui-overrides] 赋礼已从事件池移除，改抽 " .. newEvent)
      end
      effect.__fengsui_fuli_gate = true
    end

    -- ② 赋礼效果：不再要求当前事件是赋礼，改由九变篇开关决定
    if effect.event == fk.EventPhaseChanging and type(effect.triggerable) == "function" and
      not effect.__fengsui_fuli_switch then
      effect.triggerable = function(self, event, target, player, data)
        if player ~= target or player.dead or data.phase ~= Player.Draw or data.skipped then
          return false
        end
        local room = player.room
        if not room.getSettings then return false end
        local value = room:getSettings("fengsui_enable_nine_variations")
        return value == true or value == 1 or value == "1" or value == "true"
      end
      effect.__fengsui_fuli_switch = true
      fk.qInfo("[fengsui-overrides] 赋礼效果改为九变篇开关控制")
    end
  end
end

local function runAllOverrides()
  guardDoNotify()
  guardQiceInteraction()
  fixDufuDraw()
  overridePartWays()
  overrideFangziReveal()
  gateFuliEvent()
  overrideSijian()
  overrideKylinBowPrompt()
  overrideBianfurenGender()
  overrideLukangKeshou()
  overrideTianxiang()
  -- 华歆〖息兵〗官方代码本身正确，fengsui 的双方全明置门禁补丁已停用（2026-11-23）。
  -- overrideXibing()
  fixLuoyiStacking()
  trackJiananReveal()
  muteDaoliSkills()
  guardArchiveSkills()
  -- 左慈替换单独包一层：即使该模块缺失或报错，也不影响上面的覆盖。
  Pcall(function()
    local zuoci = require "packages.fengsui.pkg.zuoci_compat"
    zuoci.apply()
  end)
end

-- 挂在 Package.install 上：每装完一个包就重试一轮覆盖。
-- 各覆盖均有幂等标记/存在性检查，多次执行安全；pcall 确保覆盖自身的
-- 意外错误不会打断包安装。
if not Package._fengsuiInstallHook then
  local origInstall = Package.install
  Package.install = function(self, engine)
    origInstall(self, engine)
    Pcall(runAllOverrides)
  end
  Package._fengsuiInstallHook = true
end

-- 兜底：若某些包在 require 本文件之前已 install（standard 等前置包），立即补跑一轮。
Pcall(runAllOverrides)

return true
end)()
local __fengsui_cleanup = (function()
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
end)()

-- 智能 AI 补丁：给烽燧与国战技能补齐策略。
-- 用 pcall 包住，补丁本身出问题也不影响整个扩展加载。
local ok_ai, fengsui_ai = pcall(require, "packages/fengsui/pkg/fengsui_ai")
if ok_ai and fengsui_ai and fengsui_ai.install then
  local ok_install, err_install = pcall(fengsui_ai.install)
  if not ok_install then
    fk.qWarning(string.format("[fengsui-ai] 安装失败：%s", tostring(err_install)))
  end
  -- 房间重载时也重新挂一次钩子，避免模块被缓存后漏装
  pcall(function()
    Fk:addPostLoadFunc(function()
      pcall(fengsui_ai.install)
    end)
  end)
elseif not ok_ai then
  fk.qWarning(string.format("[fengsui-ai] 加载失败：%s", tostring(fengsui_ai)))
end

-- Voice overrides are loaded last so official packages cannot replace them.
Fk:loadTranslationTable{
  ["fengsui_hebi"] = "烽燧燎原-合璧",
  ["fengsui_hebi_choice"] = "合璧",
  ["$heg__chengguan1"] = "摧城不必急火，溃堤只需蚁穴。",
  ["$heg__chengguan2"] = "这点本事，也敢来挡我的路。",
  ["$heg__chengguan_heg__simaying1"] = "摧城不必急火，溃堤只需蚁穴。",
  ["$heg__chengguan_heg__simaying2"] = "这点本事，也敢来挡我的路。",
  ["$heg__chuchong1"] = "杀一蠹而安宗室，此等功业，谁敢与本王争？",
  ["$heg__chuchong2"] = "同宗若敢挡路，也不过是另一条虫！",
  ["$heg__chuchong3"] = "孙秀妖佞已诛，赵王逆党一个也休想逃！",
  ["$heg__chuchong4"] = "本王奉诏举义，诛的正是朝廷蠹虫！",
  ["$heg__chuchong_heg__simajiong1"] = "杀一蠹而安宗室，此等功业，谁敢与本王争？",
  ["$heg__chuchong_heg__simajiong2"] = "同宗若敢挡路，也不过是另一条虫！",
  ["$heg__chuchong_heg__simajiong3"] = "孙秀妖佞已诛，赵王逆党一个也休想逃！",
  ["$heg__chuchong_heg__simajiong4"] = "本王奉诏举义，诛的正是朝廷蠹虫！",
  ["$heg__dufu1"] = "满朝皆是庸碌之辈，本王一人足以镇天下！",
  ["$heg__dufu2"] = "洛阳诸事，无须天子点头，本王说了便算！",
  ["$heg__dufu3"] = "众叛亲离又如何？这朝纲仍握在本王手中！",
  ["$heg__dufu4"] = "谁道独夫必败？本王偏要独掌山河！",
  ["$heg__dufu_heg__simajiong1"] = "满朝皆是庸碌之辈，本王一人足以镇天下！",
  ["$heg__dufu_heg__simajiong2"] = "洛阳诸事，无须天子点头，本王说了便算！",
  ["$heg__dufu_heg__simajiong3"] = "众叛亲离又如何？这朝纲仍握在本王手中！",
  ["$heg__dufu_heg__simajiong4"] = "谁道独夫必败？本王偏要独掌山河！",
  ["$heg__fengguo1"] = "速整兵马，我等宗亲共赴国难！",
  ["$heg__fengguo2"] = "奸凶谋夺皇位，我为社稷除害！",
  ["$heg__fengguo_heg__simayij1"] = "速整兵马，我等宗亲共赴国难！",
  ["$heg__fengguo_heg__simayij2"] = "奸凶谋夺皇位，我为社稷除害！",
  ["$heg__gouni1"] = "天子圣驾在此，诸公何不随行？",
  ["$heg__gouni2"] = "本王势尽，然同宗之志未绝。",
  ["$heg__gouni_heg__simayong1"] = "天子圣驾在此，诸公何不随行？",
  ["$heg__gouni_heg__simayong2"] = "本王势尽，然同宗之志未绝。",
  ["$heg__guorui1"] = "我等奉诏入京，为朝扫除奸邪。",
  ["$heg__guorui2"] = "与亮图谋者，皆连坐！",
  ["$heg__guorui_heg__simawei1"] = "我等奉诏入京，为朝扫除奸邪。",
  ["$heg__guorui_heg__simawei2"] = "与亮图谋者，皆连坐！",
  ["$heg__huluan1"] = "骨肉相残，同室操戈，但为天下除此蠢耳。",
  ["$heg__huluan2"] = "疑我、惧我、叛我者，共沉沦吧！",
  ["$heg__huluan_heg__simayue1"] = "骨肉相残，同室操戈，但为天下除此蠢耳。",
  ["$heg__huluan_heg__simayue2"] = "疑我、惧我、叛我者，共沉沦吧！",
  ["$heg__mieyi1"] = "暂敛锋芒，待时而动。",
  ["$heg__mieyi2"] = "不识天命者，不得天葬！",
  ["$heg__mieyi_heg__simayong1"] = "暂敛锋芒，待时而动。",
  ["$heg__mieyi_heg__simayong2"] = "不识天命者，不得天葬！",
  ["$heg__neiji1"] = "顾命之权，岂可旁落汝南！",
  ["$heg__neiji2"] = "贾氏难制，当以亲党宿卫宫禁。",
  ["$heg__neiji_heg__yangjun1"] = "顾命之权，岂可旁落汝南！",
  ["$heg__neiji_heg__yangjun2"] = "贾氏难制，当以亲党宿卫宫禁。",
  ["$heg__xiejian1"] = "朝中亲党下场，汝等的好日子到了！",
  ["$heg__xiejian2"] = "图财还是保命？亦或者，玉石俱焚？",
  ["$heg__xiejian_heg__sunxiuj1"] = "朝中亲党下场，汝等的好日子到了！",
  ["$heg__xiejian_heg__sunxiuj2"] = "图财还是保命？亦或者，玉石俱焚？",
  ["$heg__yinfu1"] = "滔天之势，与日俱盛。",
  ["$heg__yinfu2"] = "权柄之下，何来异声？",
  ["$heg__yinfu_heg__simayue1"] = "滔天之势，与日俱盛。",
  ["$heg__yinfu_heg__simayue2"] = "权柄之下，何来异声？",
  ["$heg__yinsha1"] = "臣且听闻朝野欲废后，而得以复拥太子，甚为狂肆！",
  ["$heg__yinsha2"] = "今且缓其事，贾后必害太子，然后废后，为太子报仇，亦足以立功，岂徒免祸而已。",
  ["$heg__yinsha_heg__sunxiuj1"] = "臣且听闻朝野欲废后，而得以复拥太子，甚为狂肆！",
  ["$heg__yinsha_heg__sunxiuj2"] = "今且缓其事，贾后必害太子，然后废后，为太子报仇，亦足以立功，岂徒免祸而已。",
  ["~heg__simajiong"] = "司马乂小儿……本王竟败在你手！",
  ["~heg__simawei"] = "我今就死，天下将乱，谁能苟全？",
  ["~heg__simayij"] = "金墉城冷，人心更寒。",
  ["~heg__simaying"] = "我死之后，天下安乎不安乎？",
  ["~heg__simayong"] = "保守孤城，仍不足焉？",
  ["~heg__simayue"] = "天不佑晋，岂我一人之过。",
  ["~heg__sunxiuj"] = "许我虚名，归我老去，成败转头即非白，哈哈哈......",
  ["~heg__yangjun"] = "宫门生变，杨氏休矣，唉......",
  ["~ol_heg__caozhi"] = "命若朝霜。",
  ["$ol_heg__jiushi_ol_heg__caozhi1"] = "嘉仪氏之造思，亮兹美之独珍。",
  ["$ol_heg__jiushi_ol_heg__caozhi2"] = "饮者并醉，纵横喧哗。",
  ["$ol_heg__zongpei_ol_heg__caozhi1"] = "顾秋华而零落，感岁莫而伤心。",
  ["$ol_heg__zongpei_ol_heg__caozhi2"] = "吐粲若兮霓户，绝阿阁乎落英。",
  ["$heg__liaoye1"] = "这晋室江山，本宫要它烧成何样，它便是何样！",
  ["$heg__liaoye2"] = "尔等尽管选边，留下的那一边，本宫亲自烧个干净。",
  ["$heg__liaoye3"] = "区区朝臣，也敢妄议本宫的手段？",
  ["$heg__liaoye4"] = "烈火焚城，正好替本宫筛尽忤逆之徒。",
  ["$heg__liaoye_heg__jiananfeng1"] = "这晋室江山，本宫要它烧成何样，它便是何样！",
  ["$heg__liaoye_heg__jiananfeng2"] = "尔等尽管选边，留下的那一边，本宫亲自烧个干净。",
  ["$heg__liaoye_heg__jiananfeng3"] = "区区朝臣，也敢妄议本宫的手段？",
  ["$heg__liaoye_heg__jiananfeng4"] = "烈火焚城，正好替本宫筛尽忤逆之徒。",
  ["$heg__fangzi1"] = "废谁立谁，不过本宫一句话罢了。",
  ["$heg__fangzi2"] = "位置坐得久了，便真当自己配得上？",
  ["$heg__fangzi3"] = "今日借你一席之地，明日便可收你一条命。",
  ["$heg__fangzi4"] = "朝堂如棋，诸位都是本宫手中的子。",
  ["$heg__fangzi_heg__jiananfeng1"] = "废谁立谁，不过本宫一句话罢了。",
  ["$heg__fangzi_heg__jiananfeng2"] = "位置坐得久了，便真当自己配得上？",
  ["$heg__fangzi_heg__jiananfeng3"] = "今日借你一席之地，明日便可收你一条命。",
  ["$heg__fangzi_heg__jiananfeng4"] = "朝堂如棋，诸位都是本宫手中的子。",
  ["$heg__liudu1"] = "本宫纵入黄泉，也要看司马氏骨肉相食！",
  ["$heg__liudu2"] = "毒已入骨，尔等谁也休想独善其身！",
  ["$heg__liudu3"] = "杀了本宫又如何？这天下早已烂透了！",
  ["$heg__liudu4"] = "来啊，且看这满朝冠冕还能撑到几时！",
  ["$heg__liudu_heg__jiananfeng1"] = "本宫纵入黄泉，也要看司马氏骨肉相食！",
  ["$heg__liudu_heg__jiananfeng2"] = "毒已入骨，尔等谁也休想独善其身！",
  ["$heg__liudu_heg__jiananfeng3"] = "杀了本宫又如何？这天下早已烂透了！",
  ["$heg__liudu_heg__jiananfeng4"] = "来啊，且看这满朝冠冕还能撑到几时！",
  ["~heg__jiananfeng"] = "贾氏竟败于尔等鼠辈……本宫不服！",
  ["$heg__fuzheng1"] = "承景王之嗣，当佐宗室以安社稷。",
  ["$heg__fuzheng2"] = "宗亲有难，攸岂可袖手旁观。",
  ["$heg__fuzheng3"] = "辅弼朝纲，所念唯国，不计私门。",
  ["$heg__fuzheng4"] = "愿移此位，换宗室一脉得安。",
  ["$heg__yunde1"] = "德不独善，当分惠于宗亲。",
  ["$heg__yunde2"] = "知人而后任之，量才而后授之。",
  ["$heg__yunde3"] = "兄弟同心，何必以储位相疑。",
  ["$heg__yunde4"] = "进不争权，退不避责，此为臣节。",
  ["~SP_heg__simayou"] = "臣弟别无他志，陛下何以疑我至此……",
  ["$heg__xiace_fengsui_heg__lujii1"] = "观古今于须臾，察得失于方寸。",
  ["$heg__xiace_fengsui_heg__lujii2"] = "审势而后落子，制敌只在一念。",
  ["$ld__qice_fengsui_heg__lujii1"] = "笼天地于形内，挫万物于笔端。",
  ["$ld__qice_fengsui_heg__lujii2"] = "入洛非为虚名，当以奇谋匡济时艰。",
  ["~fengsui_heg__lujii"] = "华亭鹤唳，可复闻乎？",
  ["$heg__bingxin_fengsui_heg__huoyi1"] = "南疆霜重，报国丹心未曾冷却；",
  ["$heg__bingxin_fengsui_heg__huoyi2"] = "心虽如寒玉，烈魂独照吾心！",
  ["$heg__bingxin_fengsui_heg__huoyi3"] = "心若冰壶澄澈，何惧世道浊流！",
  ["$heg__bingxin_fengsui_heg__huoyi4"] = "寒锋可摧玉骨，不可折吾忠魂！",
  ["$niaoxiang_fengsui_heg__huoyi1"] = "诸军分翼而进，合围勿纵！",
  ["$niaoxiang_fengsui_heg__huoyi2"] = "斩势断其路，一击定南疆！",
  ["$niaoxiang_fengsui_heg__huoyi3"] = "鹰击长空万里，何惧风雨如晦！",
  ["$niaoxiang_fengsui_heg__huoyi4"] = "鹏翼乘风起，一举越千山！",
  -- 出牌阶段由国战规则临时挂上的「合纵」。原译文在 hegemony 的 strategic_advantage 子包里，
  -- 本模式若没加载到那份，技能按钮会因取不到名字而显示成【 】空框，这里补一份兜底。
  ["alliance&"] = "合纵",
  [":alliance&"] = "出牌阶段限一次，你可将有“合”标记的至多三张手牌交给与你势力不同或未确定势力的一名角色，若你以此法交给与你势力不同的角色牌，你摸等量的牌。",
  ["#alliance&"] = "合纵：你可将至多3张有“合”标记的手牌交给势力不同或无势力的角色，前者你摸等量的牌",
}


return {
  fengsui_hebi,
  fengsui_cards,
  fengsui_liwu,
  fengsui_shiyi,
  fengsui_effect,
  fengsui_mode,
  fengsui_titles,
  fengsui_skins,
}



