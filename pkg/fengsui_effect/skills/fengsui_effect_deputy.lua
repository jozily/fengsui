--[[ ==========================================================================
  烽燧燎原 · 「变更副将 / 合璧」特效（自包含安装模块）

  ▍本模块只做两件事，不改动任何已有技能、不修改官方 hegemony 包：
     1. 监听 HegUtil.GeneralTransformed  —— 变更副将（含暗置 / 主将 / 合璧换将）
     2. 猴补 compat.askToHebiOrTransform  —— 主动合璧（10 个合璧技能共用的唯一入口）

  ▍文件清单（删掉这两项即完全恢复原状，无残留、无需改动其他文件）：
     packages/fengsui/pkg/fengsui_effect/skills/fengsui_effect_deputy.lua   ← 本文件
     packages/fengsui/pkg/fengsui_effect/qml/deputy/                         ← 特效 QML 目录

  ▍为什么无需注册：包入口 init.lua 已调用 loadSkillSkelsByPath("./…/skills")，
     本目录下任何 .lua 都会被自动 require 并作为技能骨架装载；带 global=true 的
     效果由 GameLogic:prepareGlobalSkills 自动安装为全局触发器。

  ▍为什么要抢在别的技能前面：这个效果本身不弹任何选项，只负责「把画面推出去」。
     如果优先级低于其它监听 GeneralTransformed 的技能，它们的选牌/弃牌提示会先
     弹出来，动画命令排在提示之后，玩家就会觉得「换完还要点一下才播」。因此这里
     用高优先级（引擎规则：数值越大越优先，默认 1）先把动画发出去。

  ▍画面构成：主将 + 副将「成对」出现，只有被换掉的那张做入场与定型动效。

  ▍特效强度：Fk._fengsuiEffectLevel 或房间设置 fengsui_effect_level
     0 = 全关（不播任何画面）
     1 = 轻量（只播光带 + 新将，约 0.8 秒）
     2 = 完整（默认，约 1.9 秒）
     合璧特效仅在 2 档播放；1 档时合璧退化为轻量换将，不重复播。
========================================================================== ]]

local H = require "packages.fengsui.hegemony_util" -- compat 层（含官方 util）

local ROOT = "packages/fengsui/pkg/fengsui_effect/qml/deputy/"

local CFG = {
  enabled   = true, -- 总开关：false 时本模块全部静默
  level     = 2,    -- 默认强度（0 / 1 / 2）
  full_ms   = 1900, -- 完整档占用「单槽」时长
  hebi_ms   = 2500,
  lite_ms   = 850,
}

--------------------------------------------------------------------------
-- 基础设施
--------------------------------------------------------------------------

-- 注意：os.getms 实际返回的是微秒（fk.GetMicroSecond = socket.gettime() * 1e6），
-- 名字有误导，这里统一换成毫秒再比较。
local function nowMs()
  return (os.getms and os.getms() or 0) / 1000
end

-- roomScene.bigAnim 是全客户端唯一的 Loader，后发特效会覆盖前一个。
-- 这里只记录「刚刚有特效在播」，用于把档位降成轻量，绝不做延迟等待——
-- 一旦 room:delay，动画就会排到别的提示后面，手感立刻变差。
local busy_until = setmetatable({}, { __mode = "k" })

local function isBusy(room)
  local t = busy_until[room]
  return t ~= nil and t > nowMs()
end

-- 合璧换将期间，暂存普通变将特效的参数，等外层函数返回后再决定播哪个。
local stash = setmetatable({}, { __mode = "k" })

local function effectLevel(room)
  if not CFG.enabled then return 0 end
  local lv = tonumber(Fk._fengsuiEffectLevel)
  if lv == nil and room and room.getSettings then
    lv = tonumber(room:getSettings("fengsui_effect_level"))
  end
  if lv == nil then lv = CFG.level end
  return lv
end

local function modeOk(room)
  local mode = room:getSettings("gameMode")
  return mode == "fengsui_heg__mode" or mode == "new_heg_mode"
end

---@return boolean played
local function play(room, qml, payload, duration, tier)
  if effectLevel(room) <= 0 then return false end
  -- 槽位被占时降级为轻量档，但依然立刻发出，不等待、不 yield。
  if isBusy(room) and tier == "full" and payload.tier ~= nil then
    payload.tier = "lite"
    duration = CFG.lite_ms
  end
  busy_until[room] = nowMs() + math.max(300, (duration or CFG.full_ms) - 350)
  room:doSuperLightBox(ROOT .. qml, payload)
  return true
end

local function kingdomOf(player)
  local k = player:getMark("__heg_kingdom")
  if type(k) ~= "string" or k == "" then k = player.kingdom end
  if type(k) ~= "string" or k == "" or k == "unknown" then k = "qun" end
  return k
end

-- 取某一边的「最终可见将名」。暗置的将在这个模组里字段本身就是 "anjiang"，
-- 但为防个别路径残留真名，调用方对暗置侧会再强制抹一次。
local function cardName(player, isMain)
  local name = isMain and player.general or player.deputyGeneral
  if type(name) ~= "string" or name == "" then return "anjiang" end
  return name
end

--------------------------------------------------------------------------
-- 参数构造
--
-- 画面要的是「这一对将」，所以主将、副将各送一张，再告诉 QML 哪一张被换了。
-- 被换的那张做入场 + 定型；另一张只是陪衬，静态亮起。
--------------------------------------------------------------------------
local function transformPayload(player, data)
  local isHidden = data.isHidden == true
  local isMain = data.isMain == true

  local mainName = cardName(player, true)
  local deputyName = cardName(player, false)
  -- 暗置侧一律由服务端抹平，绝不交给客户端判断，避免泄露
  if isHidden then
    if isMain then mainName = "anjiang" else deputyName = "anjiang" end
  end

  local lv = effectLevel(player.room)
  local titleKey = isMain and "#fengsui_effect_change_main"
      or (isHidden and "#fengsui_effect_change_deputy_hidden"
          or "#fengsui_effect_change_deputy")
  return {
    seat      = player.seat,
    playerId  = player.id,
    main      = mainName,
    deputy    = deputyName,
    changed   = isMain and "main" or "deputy",
    isHidden  = isHidden,
    kingdom   = kingdomOf(player),
    title     = Fk:translate(titleKey),
    tier      = lv >= 2 and "full" or "lite",
  }
end

local function hebiPayload(player, skillName)
  return {
    seat      = player.seat,
    playerId  = player.id,
    main      = cardName(player, true),
    deputy    = cardName(player, false),
    changed   = "deputy",
    kingdom   = kingdomOf(player),
    skillName = skillName or "",
    title     = Fk:translate("#fengsui_effect_hebi"),
    -- 刻意不给 tier：合璧没有轻量档，play() 里就不会把它降级成 lite
  }
end

--------------------------------------------------------------------------
-- 合璧入口挂钩：compat.askToHebiOrTransform
--   覆盖 bizun / fenchai / hejue / menyin / qiaoshi / ranlv / shenqing /
--        weihou / xunyun / yudao 十个技能，零改动。
--   合璧分支内部走 changeGeneral → GeneralTransformed，若直接在该事件里播
--   换将特效就会和玉璧特效双播。所以进入函数时给导演层挂一个「暂存」，
--   事件先只记录参数不播；出函数后按「companion 标记是否增加」判定分支。
--------------------------------------------------------------------------

local function installHebiHook()
  if H.__fengsui_effect_hebi_hooked then return end
  local original = H.askToHebiOrTransform
  if type(original) ~= "function" then return end

  H.askToHebiOrTransform = function(room, player, skillName, cancelable)
    if not room or not player then
      return original(room, player, skillName, cancelable)
    end
    local beforeMark = tonumber(player:getMark("@!!companion")) or 0
    local box = {}

    stash[room] = box
    local ok = original(room, player, skillName, cancelable)
    stash[room] = nil

    if not ok then
      -- 取消时不播；但若中途确实换了将（记录了 payload），照样补上。
      if box.payload then
        play(room, "TransformDeputy.qml", box.payload, CFG.full_ms, box.payload.tier)
      end
      return ok
    end

    local afterMark = tonumber(player:getMark("@!!companion")) or 0
    local isHebi = afterMark > beforeMark

    if isHebi and effectLevel(room) >= 2 then
      play(room, "HebiDeputy.qml", hebiPayload(player, skillName), CFG.hebi_ms, "full")
    elseif box.payload then
      -- 未成合璧（无配对 / 1 档强度）：补播普通换将特效。
      play(room, "TransformDeputy.qml", box.payload, CFG.full_ms, box.payload.tier)
    end
    return ok
  end

  H.__fengsui_effect_hebi_hooked = true
end

--------------------------------------------------------------------------
-- 技能骨架：全局触发，无需授予给任何角色
--------------------------------------------------------------------------

local effectDeputy = fk.CreateSkill{
  name = "#fengsui_effect_deputy",
  -- 必须带锁定技标签：TriggerSkill 的 cost 在无 Compulsory 时会走
  -- room:askToSkillInvoke 问一句「是否发动 xxx」，这就是玩家看到的那个多余提示。
  -- mute 只关配音，管不住询问。
  tags = { Skill.Compulsory },
}

effectDeputy:addEffect(H.GeneralTransformed, {
  global = true,
  mute = true,
  -- 越大越优先（默认 1，装备 0.1，规则 0）。
  -- 必须排在其它监听 GeneralTransformed 的技能之前：它们会弹选牌提示，
  -- 一旦先弹，动画命令就被押后，表现为「换完要点一下才播」。
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    if not target or target ~= player then return false end
    local room = player.room
    if not room or effectLevel(room) <= 0 then return false end
    return modeOk(room)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local payload = transformPayload(player, data)
    local box = stash[room]
    if box ~= nil then
      -- 正在 askToHebiOrTransform 内部：只记录，出栈后统一播。
      box.payload = payload
      return
    end
    play(room, "TransformDeputy.qml", payload, CFG.full_ms, payload.tier)
  end,
})

installHebiHook()

Fk:loadTranslationTable{
  -- 技能名也要有译文：即便哪天标签失效，弹窗也不会露出 #fengsui_effect_deputy 这种裸键
  ["#fengsui_effect_deputy"]               = "烽燧·变更副将特效",
  ["#fengsui_effect_change_deputy"]        = "变更副将",
  ["#fengsui_effect_change_deputy_hidden"] = "变更副将·暗置",
  ["#fengsui_effect_change_main"]          = "主将变更",
  ["#fengsui_effect_hebi"]                 = "珠联璧合",
}

return effectDeputy
