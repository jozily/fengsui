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

-- 官方卞夫人两个版本（nos_heg__bianfuren / ld__bianfuren）漏设女性性别，仅 ol 版正确。
local function overrideBianfurenGender()
  for _, name in ipairs({ "nos_heg__bianfuren", "ld__bianfuren" }) do
    local g = Fk.generals and Fk.generals[name]
    if g and g.gender ~= General.Female then
      g.gender = General.Female
    end
  end
end

overrideBianfurenGender()

-- 官方陆抗〖恪守〗(ld__keshou) 回合开始刷新时读错标记名（写成 @keshou，
-- 实际标记为 @ld__keshou），导致“下回合受到的伤害-1”永不生效。这里替换刷新分支。
local function overrideLukangKeshou()
  local related = (Fk.related_skills and Fk.related_skills["ld__keshou"]) or {}
  for _, effect in ipairs(related) do
    if effect.event == fk.TurnStart and not effect.__fengsui_keshou_override then
      effect.on_refresh = function(self, event, target, player, data)
        local room = player.room
        for _, p in ipairs(room.alive_players) do
          if p:getMark("@ld__keshou") > 0 then
            room:setPlayerMark(p, "@ld__keshou-turn", p:getMark("@ld__keshou"))
            room:setPlayerMark(p, "@ld__keshou", 0)
          end
        end
      end
      effect.__fengsui_keshou_override = true
    end
  end
end

overrideLukangKeshou()

-- 官方小乔〖天香〗(hs__tianxiang) 两处问题：
-- 1. can_trigger 不检查是否持有可弃的♥手牌，也不检查选项是否为空；
-- 2. 当“失去体力”分支本回合已用且伤害来源已死亡时，on_use 的 askToChoice
--    会拿到空选项列表而报错。这里在触发条件里补上这两层保护。
local function overrideTianxiang()
  local related = (Fk.related_skills and Fk.related_skills["hs__tianxiang"]) or {}
  for _, effect in ipairs(related) do
    if effect.event == fk.DetermineDamageInflicted and not effect.__fengsui_tianxiang_override then
      local old_triggerable = effect.can_trigger
      effect.can_trigger = function(self, event, target, player, data)
        if not old_triggerable(self, event, target, player, data) then return false end
        -- 需有可弃的♥手牌（红颜转化后♠按♥计）
        local hasHeart = table.find(player:getCardIds("h"), function(id)
          local suit = Fk:getCardById(id):getSuitString()
          return suit == "heart" or (suit == "spade" and player:hasSkill("hs__hongyan"))
        end)
        if not hasHeart then return false end
        -- 至少一项可选，避免空选项报错
        local loseHpOk = player:getMark("hs__tianxiang_loseHp-turn") == 0
        local damageOk = player:getMark("hs__tianxiang_damage-turn") == 0 and
          data.from and not data.from.dead
        return loseHpOk or damageOk
      end
      effect.__fengsui_tianxiang_override = true
    end
  end
end

overrideTianxiang()

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
