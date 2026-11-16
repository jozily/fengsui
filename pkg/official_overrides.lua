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

local function runAllOverrides()
  guardDoNotify()
  guardQiceInteraction()
  fixDufuDraw()
  overrideSijian()
  overrideKylinBowPrompt()
  overrideBianfurenGender()
  overrideLukangKeshou()
  overrideTianxiang()
  overrideXibing()
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
