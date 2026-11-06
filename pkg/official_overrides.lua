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

-- 官方小乔〖天香〗(hs__tianxiang) 两处问题：
-- 1. can_trigger 不检查是否持有可弃的♥手牌，也不检查选项是否为空；
-- 2. 当“失去体力”分支本回合已用且伤害来源已死亡时，on_use 的 askToChoice
--    会拿到空选项列表而报错。这里在触发条件里补上这两层保护。
local function overrideTianxiang()
  for _, effect in ipairs(collectTriggerEffects("hs__tianxiang")) do
    if effect.event == fk.DetermineDamageInflicted and not effect.__fengsui_tianxiang_override then
      -- spec.can_trigger 已被捕获进 triggerable 闭包，包裹 triggerable 才有效。
      local old_triggerable = effect.triggerable
      if old_triggerable then
        effect.triggerable = function(_self, event, target, player, data)
          if not old_triggerable(_self, event, target, player, data) then return false end
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
        fk.qInfo("[fengsui-overrides] hs__tianxiang(天香) triggerable 已包裹")
      end
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
-- 技能名询问框（例如碧玉用现版取声时，旧版 qushengRemake 仍弹「取声·旧」）。
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

local function runAllOverrides()
  overrideSijian()
  overrideKylinBowPrompt()
  overrideBianfurenGender()
  overrideLukangKeshou()
  overrideTianxiang()
  muteDaoliSkills()
  guardArchiveSkills()
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
