-- 风燧对官方技能的运行时兼容覆盖。
-- 这里不改 packages/hegemony 的源文件；官方技能加载完成后，仅替换触发条件。

local function overrideSijian()
  local main = Fk.skills and Fk.skills.sijian
  if not main then return end
  local related = (Fk.related_skills and Fk.related_skills.sijian) or main.related_skills or {}
  for _, effect in ipairs(related) do
    if effect.event == fk.AfterCardsMove and not effect.__fengsui_sijian_override then
      local old_triggerable = effect.triggerable
      effect.triggerable = function(self, event, target, player, data)
        if not player or not player:isKongcheng() then return false end
        return old_triggerable(self, event, target, player, data)
      end
      effect.__fengsui_sijian_override = true
    end
  end
end

overrideSijian()

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

overrideKylinBowPrompt()

-- 这些技能只负责悼离的阶段清理/特效，不应在战报中生成“【】”或
-- “【悼离骤雨】”。部分旧引擎版本不会把骨架上的 mute 完整复制到
-- 延迟触发器，因此在所有扩展技能实例创建后再强制静默一次。
for name, skill in pairs(Fk.skills or {}) do
  if name == "#fengsui_effect_daoli_rain" or
      name:startsWith("#fengsui_heg__daoli_") then
    skill.mute = true
    skill.audio_index = 0
    skill.no_indicate = true
  end
end

return true
