--[[ ==========================================================================
  烽燧燎原 · 「酣世」额外回合 · 梦泽仙气氛围（自包含安装模块）

  ▍本模块只做一件事：酣世让某名角色进行的那个额外回合里，全屏飘一层蓝色仙气，
     回合结束自动散去。不改动酣世/矢北的任何逻辑，也不改官方 hegemony 包。

  ▍判定钥匙（只看回合原因，不看任何标记）：
       起雾   fk.TurnStart  data.reason == "fengsui_heg__hanshi"
       散雾   fk.TurnEnd    data.reason == "fengsui_heg__hanshi"
     额外回合的 TurnData.reason 就是 gainAnExtraTurn 传进去的技能名，普通回合是
     "game_rule"，所以这一对判断恰好圈住整个额外回合，无需自己计时。
     另留一条 fk.Death 兜底：额外回合里途阵亡时 TurnEnd 不一定按常规跑，读到
     fengsui_heg__hanshi_shibei 标记就收雾。

  ▍文件清单（删掉这三项即完全恢复原状，无残留）：
     packages/fengsui/pkg/fengsui_effect/skills/fengsui_effect_hanshi_aura.lua  ← 本文件
     packages/fengsui/pkg/fengsui_effect/qml/deputy/FairyAura.qml               ← 仙气本体 + 梦境 BGM 播放器
     packages/fengsui/pkg/fengsui_effect/audio/BGM/dream_hanshi.mp3             ← BGM 音源（96 s 无缝循环 + 电平归一化）

  ▍BGM 说明：曲子是 leberch《Ambient Dreams》（Pixabay 免费素材），原始 185 s、
     44.1 kHz 立体声 256 kbps、Integrated -23.5 LUFS，首尾各有一段淡入淡出与静音，
     直接循环会「断」。已截取 50–150 s 段、首尾 4 s 等功率交叉淡化做成 96 s 无缝循环，
     再 +7 dB 并限幅到 -1.4 dB 峰值（成品 mean -20.7 dB / -17.3 LUFS，与游戏 BGM
     的 -17.5 dB 同档）；播放时由 QML 再乘效果音量 × 0.55，落在游戏 BGM 之下。
     换素材务必重做「交叉淡化 + 电平归一化」两步，否则不是接缝爆音就是听不见。
     播放期间游戏 BGM 会被临时压到 32%、散雾时还原（QML 内的 duckGameBgm 开关）。

  ▍为什么不写在酣世里：酣世是规则技能，视觉层单独一份，卸载特效不影响对局逻辑。

  ▍为什么全部走 on_trigger：不产生 SkillEffect，因此不询问（省掉 Compulsory 依赖）、
     不播技能语音、不打「发动技能」日志——画面本来就是纯氛围，不该在聊天记录里留痕。

  ▍为什么每条都写了 can_trigger、且优先级各不同：没写 can_trigger 的 global 效果，
     TriggerSkill:triggerable 的默认实现认为它「随时可发动」（对每个座位都成立），
     同一优先级下凑够两项，触发循环就会真弹一个「选择要发动的技能」选框
     （trigger_event.lua:158，单选项才会自动跳过）。本模块用 3 / 6，
     与酣世发矢北（2）、矢北收回（5）错开，避免被合并进同一个选框。
========================================================================== ]]

local ROOT = "packages/fengsui/pkg/fengsui_effect/qml/deputy/"

local CFG = {
  enabled = true,                 -- 总开关：false 时本模块完全静默
  mark = "fengsui_heg__hanshi_shibei",
  turnReason = "fengsui_heg__hanshi",
  levelMin = 1,                   -- 特效强度低于此值时整段跳过（0 = 全关）
  defaultLv = 2,
}

local aura = fk.CreateSkill {
  name = "#fengsui_effect_hanshi_aura",
  tags = { Skill.Compulsory },
  mute = true,
}

-- 与 fengsui_effect_deputy.lua 共用同一套强度档
local function effectLevel(room)
  if not CFG.enabled then return 0 end
  local lv = tonumber(Fk._fengsuiEffectLevel)
  if lv == nil and room and room.getSettings then
    lv = tonumber(room:getSettings("fengsui_effect_level"))
  end
  if lv == nil then lv = CFG.defaultLv end
  return lv
end

local function setAura(room, running)
  room:doSuperLightBox(ROOT .. "FairyAura.qml", { running = running })
end

-- 起雾 / 散雾都只看回合原因，不依赖任何技能标记，因此酣世那边怎么改都不影响这里，
-- 也不会出现「标记没置上、雾散不掉」的情况。
--
-- 三条都必须写 can_trigger，且各用一个不与他人相同的优先级。原因是引擎的触发循环：
-- 没写 can_trigger 的 global 效果，TriggerSkill:triggerable 认为它「随时可发动」
-- （对每个座位都成立），同一优先级下凑够两项就会真的弹「选择要发动的技能」选框
-- （trigger_event.lua:158）。先前 TurnStart 与酣世同为 2、TurnEnd 与矢北同为 5，
-- 于是每次回合开始、每次额外回合结束都会弹一个选框，里面一项写着「酣世」、一项是空标题。
-- 现在：起雾 3（酣世发矢北是 2）、散雾 6（矢北收回是 5），各走各的，单选项自动跳过。
-- 依旧走 on_trigger：不产生 SkillEffect，不询问、不播语音、不在日志里留痕。
aura:addEffect(fk.TurnStart, {
  global = true,
  priority = 3,
  can_trigger = function(self, _, target, player, data)
    return target ~= nil and target == player and target:isAlive()
      and data ~= nil and data.reason == CFG.turnReason
      and effectLevel(target.room) >= CFG.levelMin
  end,
  on_trigger = function(self, _, target)
    setAura(target.room, true)
  end,
})

-- 额外回合结束 → 散雾
aura:addEffect(fk.TurnEnd, {
  global = true,
  priority = 6,
  can_trigger = function(self, _, target, player, data)
    return target ~= nil and target == player
      and data ~= nil and data.reason == CFG.turnReason
  end,
  on_trigger = function(self, _, target)
    setAura(target.room, false)
  end,
})

-- 兜底：回合中途被打断（例如额外回合里阵亡）时 TurnEnd 不一定按常规跑
aura:addEffect(fk.Death, {
  global = true,
  priority = 6,
  can_trigger = function(self, _, target, player)
    return target ~= nil and target == player and target:getMark(CFG.mark) > 0
  end,
  on_trigger = function(self, _, target)
    setAura(target.room, false)
  end,
})

for _, spec in ipairs(aura.effect_spec_list) do
  if type(spec[3]) == "table" then spec[3].mute = true end
end

Fk:loadTranslationTable {
  ["#fengsui_effect_hanshi_aura"] = "",
}

return aura
