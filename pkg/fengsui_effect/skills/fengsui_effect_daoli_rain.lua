--[[ ==========================================================================
  烽燧燎原 · 「悼离」额外出牌阶段 · 骤雨氛围（自包含安装模块）

  ▍本模块只做一件事：潘安「悼离」追加的那个额外出牌阶段里下雨，阶段结束自动停。
     不改动任何已有技能、不修改官方 hegemony 包、不需要在 init.lua 注册。

  ▍判定钥匙：玩家标记 fengsui_heg__daoli_extra
       发动悼离       daoli_util.lua:45          → 置 1
       回合结束       daoli_extra.lua:50-51      → 置 2，gainAnExtraPhase(Play)
       额外阶段开始   daoli_extra.lua:61         → phase == Play and mark == 2
       额外阶段结束   daoli_extra.lua:123-127    → cleanup() → 置 0
     所以 mark == 2 的区间恰好等于「悼离的额外出牌阶段」，回合过去自动归零，
     本模块不需要自己维护任何计时或回合钩子。

  ▍文件清单（删掉这三项即完全恢复原状，无残留）：
     packages/fengsui/pkg/fengsui_effect/skills/fengsui_effect_daoli_rain.lua  ← 本文件
     packages/fengsui/pkg/fengsui_effect/qml/deputy/RainPhase.qml              ← 雨幕 + 雨声
     packages/fengsui/pkg/fengsui_effect/audio/ambience/quiet_rain.mp3         ← 实际播放的音源（无缝循环 + 电平归一化）
   附带保留的原始素材（不参与播放，仅供重做时取用）：
     packages/fengsui/pkg/fengsui_effect/audio/source/quiet_rain_source.mp3
     音源刻意放在特效包自己的 audio/ 下（与同目录 BGM/ 同级），这样卸载特效时
     不会被遗漏在别处；QML 侧用 Qt.resolvedUrl 相对本文件定位，不用 Cpp.path
     ——包内 QML 没有 import Fk 时 Cpp 是未定义的（曾因 ReferenceError 导致静音）。
     注意电平：素材站下的雨声录音普遍极轻（这份 mean 只有 -49.4 dB，比游戏 BGM
     低 32 dB，叠上音量系数后等于静音），使用前必须先归一化，见 RainPhase.qml 头部。
     原始版 = 64.03 s / 193.8 kbps / 1 551 090 B（首尾各有约 3~4 s 淡入淡出，不能直接循环）；
     播放版 = 53.50 s / 192 kbps / 1 285 952 B（裁掉淡入淡出 + 3 s 等功率交叉淡化 + 27.7 dB 增益）。

  ▍为什么雨声能循环：不走 Backend.playSound（只能播一次性文件），
     而是让 RainPhase.qml 自带 MediaPlayer + loops: Infinite，由 QML 自己放、自己停。
     服务端只负责发「开始 / 停止」两条指令，因此这里不会有任何 yield 或 delay，
     不耽误玩家出牌结算。

  ▍为什么不用 is_delay_effect：那个字段是给「等别人结算完再动」的延迟效果用的，
     下雨要在阶段一开始就出画面，所以只用 Compulsory 跳过发动询问，并用高
     priority 抢在其他阶段开始技能弹窗之前先把画面推出去。
========================================================================== ]]

local ROOT = "packages/fengsui/pkg/fengsui_effect/qml/deputy/"

local CFG = {
  enabled    = true,                     -- 总开关：false 时本模块完全静默
  mark       = "fengsui_heg__daoli_extra",
  levelMin   = 1,                        -- 特效强度低于此值时整段跳过（0 = 全关）
  defaultLv  = 2,
}

local rain = fk.CreateSkill {
  name = "#fengsui_effect_daoli_rain",
  tags = { Skill.Compulsory },  -- 没有这个标签就会被 askToSkillInvoke 问一句「是否发动」
  mute = true,
}

-- 与 fengsui_effect_deputy.lua 共用同一套强度档：Fk._fengsuiEffectLevel 优先，
-- 其次房间设置 fengsui_effect_level，都没有则默认完整档。
local function effectLevel(room)
  if not CFG.enabled then return 0 end
  local lv = tonumber(Fk._fengsuiEffectLevel)
  if lv == nil and room and room.getSettings then
    lv = tonumber(room:getSettings("fengsui_effect_level"))
  end
  if lv == nil then lv = CFG.defaultLv end
  return lv
end

-- 恰好是悼离追加的那个出牌阶段：mark 只在回合结束时置 2，
-- 并在该阶段结束时被 cleanup 清回 0，因此这个判断不会误伤普通出牌阶段。
local function inDaoliExtraPlay(player)
  return player ~= nil
    and player.phase == Player.Play
    and player:getMark(CFG.mark) == 2
end

local function hasRain(player)
  return inDaoliExtraPlay(player) and effectLevel(player.room) >= CFG.levelMin
end

local function setRain(room, running)
  room:doSuperLightBox(ROOT .. "RainPhase.qml", { running = running })
end

-- 额外出牌阶段开始 → 下雨
rain:addEffect(fk.EventPhaseStart, {
  global = true,
  priority = 10,  -- 引擎里数值越大越优先（默认 1），先把画面发出去再让别人弹窗
  can_trigger = function(self, _, target)
    return hasRain(target)
  end,
  on_use = function(self, _, target)
    setRain(target.room, true)
  end,
})

-- 额外出牌阶段结束 → 停雨（此时 daoli_extra 的 cleanup 还没跑，mark 仍是 2）
rain:addEffect(fk.EventPhaseEnd, {
  global = true,
  priority = 10,
  can_trigger = function(self, _, target)
    return hasRain(target)
  end,
  on_use = function(self, _, target)
    setRain(target.room, false)
  end,
})

-- 兜底：阶段被中途打断（例如玩家在额外阶段里阵亡）时 EventPhaseEnd 不一定触发，
-- 这里补一条停止指令，避免雨声一直挂着。
rain:addEffect(fk.Death, {
  global = true,
  priority = 10,
  can_trigger = function(self, _, target)
    return target ~= nil and target:getMark(CFG.mark) == 2
  end,
  on_use = function(self, _, target)
    setRain(target.room, false)
  end,
})

for _, spec in ipairs(rain.effect_spec_list) do
  if type(spec[3]) == "table" then spec[3].mute = true end
end

Fk:loadTranslationTable {
  ["#fengsui_effect_daoli_rain"] = "",
}

return rain
