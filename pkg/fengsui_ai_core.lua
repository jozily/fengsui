-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- 国战 / 烽燧通用 AI 内核（独立文件，不改技能效果，只补 AI 策略）
--
-- 引擎的 SmartAI 找不到策略时的行为：
--   · 主动技 / 转化技：不出，AI 拿到武将等于没技能；
--   · 触发技：handleAskForSkillInvoke 拿不到 InvokeStrategy 就一律答"不发动"；
--   · 选择项：AskForChoices 没有任何处理器，room:askToChoice 最后退化成"选第一个"。
--
-- 本内核给一个包范围内的所有技能补上这三类策略，并按局势打分：
--   1. 主动技：枚举"选几张牌 × 选几个目标"，用敌友、血量、手牌、牌价打分；
--   2. 转化技：读 viewas 的 pattern 判断这张牌是打人、救命还是纯防御；
--   3. 触发技：默认发动，但限定技、失血、弃光手牌、移除武将有各自的时机；
--   4. 选择项：按"摸牌/回复/造成伤害"与"失去体力/翻面/弃光"打分选最优项，
--      取代原来的"永远选第一个"。

local AI = Fk.Ltk.AI

local M = {}

-- 搜索上限：面板组合是笛卡尔积，不设上限八人局会卡
local MAX_CARDS = 4
local MAX_TARGETS = 3
local MIN_SCORE = 3

-- 注册过的包范围，用于判断"这个技能归不归我们管"
local scopes = {}
local choice_installed = false
local nullify_installed = false

-- 状态技 / 转化技的关键字：它们不是"触发时机"
local NON_TRIGGER_KEYS = {
  active = true,
  viewas = true,
  cardskill = true,
  distance = true,
  prohibit = true,
  atkrange = true,
  maxcards = true,
  targetmod = true,
  filter = true,
  invalidity = true,
  visibility = true,
  bigkingdom = true,
  arraysummon = true,
}

-- 转化技产出的牌名归类
local OFFENSE_CARDS = {
  slash = true,
  fire__slash = true,
  thunder__slash = true,
  duel = true,
  fire_attack = true,
  collateral = true,
  snatch = true,
  dismantlement = true,
  supply_shortage = true,
  lure_tiger = true,
  archery_attack = true,
  barbarian_invasion = true,
}

local DEFENSE_CARDS = {
  jink = true,
  nullification = true,
}

local SELF_CARDS = {
  peach = true,
}

-- 酒这类"下一张杀加伤"的牌，出牌阶段单独判断没意义，别主动点
local BUFF_CARDS = {
  analeptic = true,
}

-- ============================================================
-- 通用小工具
-- ============================================================

local function textHas(text, word)
  return type(text) == "string" and text:find(word, 1, true) ~= nil
end

local function hasAny(text, words)
  if type(text) ~= "string" or text == "" then return false end
  for _, w in ipairs(words) do
    if text:find(w, 1, true) then return true end
  end
  return false
end

--- 取技能描述：优先动态描述，取不到退回翻译表
local function descriptionOf(name, player)
  local ok, d = pcall(function() return Fk:getDescription(name, nil, player) end)
  if ok and type(d) == "string" and d ~= "" and d ~= ":" .. name then return d end

  local ok2, d2 = pcall(function() return Fk:translate(":" .. name) end)
  if ok2 and type(d2) == "string" and d2 ~= ":" .. name then return d2 end
  return ""
end

--- 这个技能是否在某个已注册的范围内
local function inScope(name, skel)
  for _, scope in ipairs(scopes) do
    local ok, ret = pcall(scope.match, name, skel)
    if ok and ret then return true, scope end
  end
  return false, nil
end

-- ============================================================
-- 技能画像：从描述与骨架里读出"这技能想干什么"
-- ============================================================

---@class HegAI.Profile
---@field name string
---@field text string
---@field compulsory boolean
---@field limited boolean
---@field offense boolean
---@field heal boolean
---@field draw boolean
---@field disrupt boolean
---@field defense boolean
---@field control boolean
---@field reveal boolean
---@field cost_hp boolean
---@field cost_all boolean
---@field cost_show boolean
---@field cost_remove boolean
---@field has_active boolean
---@field has_viewas boolean
---@field viewas_kind string?

local profile_cache = {}

--- 取出 viewas 效果的数据表
local function viewasData(skel)
  for _, spec in ipairs(skel.effect_spec_list or {}) do
    if spec[1] == "viewas" then
      local data = spec[3] or spec[2]
      if type(data) == "table" then return data end
    end
  end
end

--- 判断转化技把牌变成什么：打人的 / 保命的 / 自己的
local function classifyViewas(data)
  local pattern = data and data.pattern
  if type(pattern) ~= "string" then return nil, nil end

  local offense, defense, selfuse, buff = false, false, false, false
  for name in pattern:gmatch("[^,|]+") do
    if OFFENSE_CARDS[name] then
      offense = true
    elseif DEFENSE_CARDS[name] then
      defense = true
    elseif SELF_CARDS[name] then
      selfuse = true
    elseif BUFF_CARDS[name] then
      buff = true
    end
  end

  local kind
  if offense then
    kind = "offense"
  elseif defense then
    kind = "defense"
  elseif selfuse then
    kind = "self"
  elseif buff then
    kind = "buff"
  end
  return kind, pattern
end

local function buildProfile(name, skel, player)
  local prof = {
    name = name,
    text = "",
    compulsory = false,
    limited = false,
    offense = false,
    heal = false,
    draw = false,
    disrupt = false,
    defense = false,
    control = false,
    reveal = false,
    cost_hp = false,
    cost_all = false,
    cost_show = false,
    cost_remove = false,
    has_active = false,
    has_viewas = false,
    viewas_kind = nil,
  }

  if type(skel.tags) == "table" then
    for _, tag in ipairs(skel.tags) do
      if tag == Skill.Compulsory then prof.compulsory = true end
      if tag == Skill.Limited or tag == Skill.Wake then prof.limited = true end
    end
  end

  -- 效果类型
  local viewas_data
  for _, spec in ipairs(skel.effect_spec_list or {}) do
    local key = spec[1]
    if key == "active" then
      prof.has_active = true
    elseif key == "viewas" then
      prof.has_viewas = true
      viewas_data = spec[3] or spec[2]
    end
  end
  if prof.has_viewas then
    prof.viewas_kind = classifyViewas(viewas_data)
  end

  -- 描述画像
  local text = descriptionOf(name, player)
  prof.text = text
  if text ~= "" then
    prof.offense = hasAny(text, {
      "造成", "伤害+1", "伤害+2", "伤害加", "流失体力",
      "【决斗】", "【火攻】", "视为使用一张【杀】", "当作【杀】", "视为对其使用",
    })
    prof.heal = hasAny(text, { "回复", "恢复" })
    prof.draw = hasAny(text, { "摸一张", "摸两张", "摸三张", "摸四张", "摸X张", "摸等量", "摸牌", "观看牌堆", "观看一名" })
    prof.disrupt = hasAny(text, { "弃置其", "弃置一名", "获得其", "获得一名", "交给", "弃置一张", "弃置两张" })
    prof.defense = hasAny(text, { "防止", "取消", "无效", "不能响应", "抵消" })
    prof.control = hasAny(text, { "不能", "无法", "跳过", "横置", "暗置", "明置", "变更副将", "易位", "翻面" })
    prof.reveal = hasAny(text, { "明置" })

    -- 防御/取消类技能常带"伤害"字样，别把它当成攻击技去点敌人
    if prof.defense and not hasAny(text, { "造成", "令其受到" }) then
      prof.offense = false
    end

    prof.cost_hp = hasAny(text, { "失去1点体力", "失去一点体力", "失去1点体力值" })
    prof.cost_all = hasAny(text, { "弃置所有", "弃置全部", "所有手牌" })
    prof.cost_show = hasAny(text, { "暗置此武将牌", "暗置另一张武将牌", "暗置你的" })
    prof.cost_remove = hasAny(text, { "移除此武将牌", "移除副将" })
  end

  -- 转化技的用途可以反推意图
  if prof.has_viewas then
    if not prof.viewas_kind then
      -- pattern 读不出来（有些技能只在 view_as 里写牌名）：从描述兜底
      if textHas(text, "当【闪】") or textHas(text, "视为【闪】")
        or textHas(text, "当【无懈可击】") or textHas(text, "视为【无懈可击】") then
        prof.viewas_kind = "defense"
      elseif textHas(text, "【酒】") then
        prof.viewas_kind = "buff"
      elseif prof.offense then
        prof.viewas_kind = "offense"
      else
        -- 说不准是什么牌，就当自用型处理：只在需要的时候点
        prof.viewas_kind = "self"
      end
    end
    if prof.viewas_kind == "offense" then
      prof.offense = true
    elseif prof.viewas_kind == "self" then
      prof.heal = true
    end
  end

  return prof
end

local function profileOf(name, skel, player)
  local cached = profile_cache[name]
  if cached then return cached end
  local ok, prof = pcall(buildProfile, name, skel or {}, player)
  if not ok or type(prof) ~= "table" then return nil end
  profile_cache[name] = prof
  return prof
end

-- ============================================================
-- 牌价与目标价
-- ============================================================

local KEY_CARDS = {
  peach = true,
  jink = true,
  nullification = true,
}

--- 弃掉这张牌有多心疼
local function cardCost(ai, cid)
  local cost = 1
  local ok, v = pcall(function() return ai:getCardValue(cid) end)
  if ok and type(v) == "number" then
    cost = cost + math.max(0, math.min(v, 6)) * 0.25
  end

  local okc, card = pcall(function() return Fk:getCardById(cid) end)
  if okc and card then
    if card.type == Card.TypeEquip then
      cost = cost + 1.2
    end
    local true_name = card.trueName or card.name
    if KEY_CARDS[true_name] then
      -- 血线上的桃/闪/无懈，多一层保命价值
      cost = cost + (ai.player.hp <= 2 and 3 or 1.6)
    elseif true_name == "slash" then
      cost = cost + 0.2
    end
  end
  return cost
end

--- 弃光手牌这类的真实代价：逐张按牌价算，桃/闪在残血时格外贵
--- （只按张数折算会把"丢掉一张桃"和"丢掉一张废牌"算成一样的）
local function handDumpValue(me)
  local ok, ids = pcall(function() return me:getCardIds("h") end)
  local okh, n = pcall(function() return me:getHandcardNum() end)
  n = (okh and type(n) == "number") and n or 3

  if not ok or type(ids) ~= "table" then return n * 0.8, n end

  local shim = { player = me, getCardValue = function() return 0 end }
  local cost = 0
  for _, cid in ipairs(ids) do
    local okc, v = pcall(cardCost, shim, cid)
    cost = cost + ((okc and type(v) == "number") and v or 1)
  end
  return cost, #ids
end

-- ============================================================
-- 势力规则：先打人多的一方
-- ============================================================
--
-- 国战与烽燧都是"一个势力全灭才算输"的算法：某势力活着的人越多，离赢越近。
-- 四个人抱团，别人一个一个打根本挡不住；两个独苗互相消耗，反而谁都赢不了。
-- 所以选目标不能只看血线和手牌，还要看"打掉他，是不是在削最该削的那一家"。
--
-- 权重放在 M.policy 里，想调直接改这里，不必翻下面的逻辑：
--   per_member      对方势力每多一人加多少分
--   big_bonus       打全场人数最多（≥2 人）的势力，额外加多少
--   solo_bonus      该势力只剩一人，可以顺手收，给一点尾刀分
--   lone_me_bonus   我方只剩自己、对面还在抱团时再加多少
--   unknown_penalty 势力没明置的角色，情报不足，先放一放（扣分）
-- 说明：未知势力在敌友判定里本来就算"友方"，这条只是双重保险。

M.policy = {
  kingdom = {
    enabled = true,
    per_member = 1.0,
    big_bonus = 4.0,
    solo_bonus = 0.8,
    lone_me_bonus = 1.0,
    unknown_penalty = 1.5,
    non_offense_scale = 0.35,
    -- 单次加成上限：八人局里最大势力也就四五人，封顶避免一家独大的局无脑集火
    max_bonus = 9.0,
  },
}

--- 取势力名：野心家按 role 算（新月杀里野心家会自动建国）
local function kingdomOf(p)
  local ok, k = pcall(function() return p.kingdom end)
  if not ok or type(k) ~= "string" or k == "" or k == "unknown" then return nil end
  if k == "wild" then
    local okr, r = pcall(function() return p.role end)
    if okr and type(r) == "string" and r ~= "" then return r end
  end
  return k
end

--- 只有国战类模式才按"势力"算：一般身份局里 player.kingdom 是武将国籍，不是阵营
local function isHegemonyMode(ai)
  local ok, mode = pcall(function() return ai.room:getSettings("gameMode") end)
  if not ok or type(mode) ~= "string" then return true end
  return mode:find("heg", 1, true) ~= nil
end

--- 数一遍场上各势力的人数：只数活着的、势力已明置的
--- 暗置角色（kingdom == "unknown"）不计入，否则等于让 AI 偷看底牌
local function kingdomContext(ai)
  local ctx = { counts = {}, mine = nil, max_count = 0, total = 0 }
  if not isHegemonyMode(ai) then
    ctx.disabled = true
    return ctx
  end

  pcall(function() ctx.mine = kingdomOf(ai.player) end)

  local ok, players = pcall(function() return ai.room.alive_players end)
  if not ok or type(players) ~= "table" then return ctx end

  for _, p in ipairs(players) do
    local k = kingdomOf(p)
    if k then
      local n = (ctx.counts[k] or 0) + 1
      ctx.counts[k] = n
      ctx.total = ctx.total + 1
      if n > ctx.max_count then ctx.max_count = n end
    end
  end
  return ctx
end

--- 打这个目标，在"势力"这一层值多少分
local function kingdomThreat(ctx, p)
  local cfg = M.policy.kingdom
  if not cfg.enabled or not ctx or ctx.disabled then return 0 end

  -- 排序比较器会对同一目标反复取值，缓存一次就够
  ctx.cache = ctx.cache or {}
  local cached = ctx.cache[p]
  if cached ~= nil then return cached end

  local val
  local k = kingdomOf(p)
  if not k then
    val = -cfg.unknown_penalty
  elseif k == ctx.mine then
    val = 0
  else
    local n = ctx.counts[k] or 1
    local mine_n = ctx.mine and (ctx.counts[ctx.mine] or 1) or 0

    val = 0
    -- 1. 对方势力人越多越该先动：削掉一个成员，他就少一份人手
    val = val + math.min(n - 1, 4) * cfg.per_member

    -- 2. 全场最大势力（≥2 人）额外加重：压不住他，最后一定被他收掉
    if n >= 2 and n >= ctx.max_count then
      val = val + cfg.big_bonus
    end

    -- 3. 只剩一人的势力没有"抱团"威胁，但尾刀顺手
    if n <= 1 then
      val = val + cfg.solo_bonus
    end

    -- 4. 我方只剩自己，对面还在抱团：不打就是等死
    if mine_n <= 1 and n >= 2 then
      val = val + cfg.lone_me_bonus
    end

    val = math.min(val, cfg.max_bonus)
  end

  ctx.cache[p] = val
  return val
end

--- 这个目标值多少分
local function targetScore(ai, p, prof, ctx)
  if p == ai.player then
    return prof.offense and -5 or 5
  end

  if ai:isFriend(p) then
    local s = prof.offense and -7 or 6
    if prof.heal and p.hp < p.maxHp then s = s + 2 end
    if prof.offense and p.hp <= 1 then s = s - 5 end
    return s
  end

  local s = prof.offense and 9 or 3
  if prof.offense then
    if p.hp <= 1 then
      s = s + 4
    elseif p.hp <= 2 then
      s = s + 1.5
    end
    local ok, n = pcall(function() return p:getHandcardNum() end)
    if ok and type(n) == "number" then
      if n >= 4 then s = s + 0.8 end
      -- 【决斗】【火攻】这类要对手掏牌来应，对方空手几乎必中
      if textHas(prof.text, "决斗") or textHas(prof.text, "火攻") then
        if n == 0 then s = s + 2.5 elseif n == 1 then s = s + 0.8 end
      end
    end
  end

  -- 势力维度：人多的一方优先，权重要按技能性质折算
  local cfg = M.policy.kingdom
  s = s + kingdomThreat(ctx, p) * (prof.offense and 1 or cfg.non_offense_scale)

  return s
end

local function pickTargets(ai, prof, n, ctx)
  local targets = ai:getEnabledTargets()
  if #targets < n then return nil end
  table.sort(targets, function(a, b)
    return targetScore(ai, a, prof, ctx) > targetScore(ai, b, prof, ctx)
  end)
  local ret = {}
  for i = 1, n do ret[i] = targets[i] end
  return ret
end

local function pickCards(ai, n)
  local cards = ai:getEnabledCards()
  if #cards < n then return nil end
  table.sort(cards, function(a, b) return cardCost(ai, a) < cardCost(ai, b) end)
  local ret = {}
  for i = 1, n do ret[i] = cards[i] end
  return ret
end

--- 试一套"n 张牌 + m 个目标"的组合
--- 注意不能调 unSelectAll，那会连技能按钮一起取消
local function tryPlan(ai, prof, n_cards, n_targets, ctx)
  ai:unSelectAllTargets()
  ai:unSelectAllCards()

  if n_cards > 0 then
    local cards = pickCards(ai, n_cards)
    if not cards then return nil end
    for _, cid in ipairs(cards) do
      ai:selectCard(cid, true)
    end
  end

  if n_targets > 0 then
    local targets = pickTargets(ai, prof, n_targets, ctx)
    if not targets then
      ai:unSelectAllCards()
      return nil
    end
    for _, p in ipairs(targets) do
      ai:selectTarget(p, true)
    end
  end

  if ai:okButtonEnabled() then
    local c = table.simpleClone(ai:getSelectedCards())
    local t = table.simpleClone(ai:getSelectedTargets())
    ai:unSelectAllTargets()
    ai:unSelectAllCards()
    return c, t
  end

  ai:unSelectAllTargets()
  ai:unSelectAllCards()
  return nil
end

--- 给一套可行方案打分
local function scorePlan(ai, prof, cards, targets, ctx)
  local me = ai.player
  local value = 4

  for _, p in ipairs(targets) do
    value = value + targetScore(ai, p, prof, ctx)
  end

  for _, cid in ipairs(cards) do
    value = value - cardCost(ai, cid)
  end

  if prof.limited then
    value = value - 10
    -- 能补刀的话，限定技不该留着
    for _, p in ipairs(targets) do
      if p ~= me and not ai:isFriend(p) and p.hp <= 1 then value = value + 14 end
    end
  end

  if prof.cost_hp then
    value = value - (me.hp <= 2 and 30 or 6)
  end
  if prof.cost_all then
    local cost, n = handDumpValue(me)
    value = value - cost * 1.1
    -- 手牌很厚的时候，一把砸光换来的那点收益撑不住
    if n >= 5 then value = value - (n - 4) * 1.5 end
  end
  if prof.cost_remove then
    value = value - (me.hp <= 1 and 0 or 25)
  end
  if prof.cost_show then
    value = value - 3
  end
  if prof.draw then
    value = value + #cards * 1.5
    local ok, n = pcall(function() return me:getHandcardNum() end)
    n = ok and n or 3
    if n <= 2 then
      value = value + 3
    elseif n >= 5 then
      -- 手牌已经很厚，再抽牌只是徒增弃牌，别为了过牌先把牌打出去
      value = value - 2
    end
  end
  if prof.heal and me.hp < me.maxHp then
    value = value + 3
  end

  -- 转化技：满血不必把桃变桃，闪和无懈在出牌阶段没有意义
  if prof.viewas_kind == "self" and not prof.offense then
    if me.hp >= me.maxHp then return -100 end
  end
  if prof.viewas_kind == "defense" or prof.viewas_kind == "buff" then return -100 end

  return value
end

--- 从技能对象上读"要选几张牌 / 几个目标"
--- 引擎的 ButtonSkill 有 getMinCardNum 之类的接口，读出来就不必瞎枚举
local function planLimits(prof, player)
  local lim = { card_min = 0, card_max = MAX_CARDS, target_min = 0, target_max = MAX_TARGETS }
  local skill = Fk.skills and Fk.skills[prof.name]
  if not skill or not skill.getMaxCardNum then return lim end

  pcall(function()
    local cmin = skill:getMinCardNum(player) or 0
    local cmax = skill:getMaxCardNum(player) or MAX_CARDS
    local tmin = skill:getMinTargetNum(player) or 0
    local tmax = skill:getMaxTargetNum(player) or MAX_TARGETS
    if type(cmin) == "number" and cmin >= 0 then lim.card_min = math.min(cmin, MAX_CARDS) end
    if type(cmax) == "number" then lim.card_max = math.min(cmax, MAX_CARDS) end
    if type(tmin) == "number" and tmin >= 0 then lim.target_min = math.min(tmin, MAX_TARGETS) end
    if type(tmax) == "number" then lim.target_max = math.min(tmax, MAX_TARGETS) end
  end)

  if lim.card_max < lim.card_min then lim.card_max = lim.card_min end
  if lim.target_max < lim.target_min then lim.target_max = lim.target_min end

  -- 转化技：一般只转一两张，读出来的 999 没有意义
  if prof.has_viewas then
    lim.card_min = math.min(lim.card_min, 1)
    lim.card_max = math.min(lim.card_max, 2)
  end
  return lim
end

local function phaseUsed(ai, name)
  local used = 0
  pcall(function()
    used = ai.player:usedSkillTimes(name, Player.HistoryPhase) or 0
  end)
  return used
end

--- 主动技 / 转化技的通用思考
local function thinkActive(prof, ai)
  local used = phaseUsed(ai, prof.name)
  if prof.text:find("出牌阶段限一次", 1, true) or prof.text:find("每阶段限一次", 1, true) then
    if used >= 1 then return nil, -100 end
  elseif used >= 2 and not prof.text:find("任意次", 1, true) then
    return nil, -100
  end

  local best, best_score = nil, MIN_SCORE - 1

  -- 势力人数在一轮思考里不会变，数一次就够，别在每个比较器里重算
  local ctx = kingdomContext(ai)

  local function scan(c_lo, c_hi, t_lo, t_hi)
    for n_cards = c_lo, c_hi do
      for n_targets = t_lo, t_hi do
        local cards, targets = tryPlan(ai, prof, n_cards, n_targets, ctx)
        if cards then
          local score = scorePlan(ai, prof, cards, targets, ctx)
          if score > best_score then
            best, best_score = { cards, targets }, score
          end
        end
      end
    end
  end

  -- 先按技能自己声明的数量精确枚举，失败再放宽
  local lim = planLimits(prof, ai.player)
  scan(lim.card_min, lim.card_max, lim.target_min, lim.target_max)
  if not best then
    scan(0, MAX_CARDS, 0, MAX_TARGETS)
  end

  ai:unSelectAllTargets()
  ai:unSelectAllCards()

  if best then return best, best_score end
  return nil, -100
end

--- 触发技是否发动
local function thinkInvoke(prof, ai)
  local me = ai.player

  if prof.compulsory then return true end

  local has_kill = false
  local ok, players = pcall(function() return ai.room.alive_players end)
  if ok and type(players) == "table" then
    for _, p in ipairs(players) do
      if p ~= me and p.hp <= 1 and not ai:isFriend(p) then
        has_kill = true
        break
      end
    end
  end

  -- 限定技/觉醒技：残血、已受伤，或者手上就有能补刀的输出技才交
  if prof.limited then
    return me.hp <= 2 or me.hp < me.maxHp or (has_kill and prof.offense)
  end

  if prof.cost_hp then
    if me.hp <= 2 then return false end
    -- 换来回复或补刀的话，掉一点血可以接受
    if (prof.heal or prof.offense) and me.hp >= 4 then return true end
  end

  if prof.cost_all then
    local cost, n = handDumpValue(me)
    if me.hp <= 2 and n >= 4 then return false end
    -- 手里全是桃和闪，换不来输出就不砸
    if cost >= 9 and not (prof.offense or prof.heal) then return false end
  end

  if prof.cost_remove and me.hp > 2 then
    return false
  end

  -- 暗置自己的武将牌：换不来摸牌/回复/输出就不值
  if prof.cost_show and not (prof.draw or prof.heal or prof.offense) then
    return false
  end

  return true
end

-- ============================================================
-- 选择项：AskForChoices（askToChoice 也走这条）
-- ============================================================

local function localizedChoice(c)
  if type(c) ~= "string" then return tostring(c) end
  local ok, t = pcall(function() return Fk:translate(c) end)
  if ok and type(t) == "string" and t ~= c then return t end
  return c
end

local ID_WORDS = {
  { "draw", 5 }, { "recover", 5 }, { "damage", 4 }, { "obtain", 4 },
  { "discard", -2 }, { "losehp", -6 }, { "lose_hp", -6 }, { "turnover", -5 },
  { "hide", -4 }, { "reveal", 2 }, { "remove", -8 }, { "cancel", 0 },
}

local function scoreChoice(ai, c)
  local me = ai.player
  local t = localizedChoice(c)
  local low = t:lower()
  local s = 0

  local num = t:match("(%d+)")
  num = num and tonumber(num) or 1

  if textHas(t, "摸") then s = s + 4 + math.min(num, 5) * 0.6 end
  if textHas(t, "回复") or textHas(t, "恢复") then
    s = s + (me.hp < me.maxHp and 6 or 1)
  end
  if textHas(t, "获得") then s = s + 4 end
  if textHas(t, "造成") then s = s + 5 end
  if textHas(t, "伤害") and not textHas(t, "受到") then s = s + 2 end
  if textHas(t, "视为使用") then s = s + 4 end
  if textHas(t, "明置") then s = s + 2 end
  if textHas(t, "合璧") or textHas(t, "珠联") then s = s + 4 end
  if textHas(t, "变更副将") or textHas(t, "易位") then s = s + 2 end

  if textHas(t, "失去") and textHas(t, "体力") then
    s = s - (me.hp <= 2 and 25 or 6)
  end
  if textHas(t, "弃置所有") or textHas(t, "弃置全部") or textHas(t, "所有手牌") then
    local okh, hand = pcall(function() return me:getHandcardNum() end)
    hand = okh and hand or 3
    s = s - (hand >= 4 and 9 or 5)
  end
  if textHas(t, "翻面") then s = s - 6 end
  if textHas(t, "交给") then s = s - 3 end
  if textHas(t, "弃置") and not textHas(t, "弃置其") and not textHas(t, "弃置一名") then
    s = s - 2
  end
  if textHas(t, "暗置") then s = s - 4 end
  if textHas(t, "移除此武将牌") then s = s - 20 end
  if textHas(t, "失去技能") or textHas(t, "视为没有") then s = s - 5 end

  for _, pair in ipairs(ID_WORDS) do
    if low:find(pair[1], 1, true) then s = s + pair[2] end
  end

  if t == "Cancel" then s = 0 end
  return s
end

--- 从 prompt 里猜技能名（askToChoice 常常不传 skill_name）
local function skillFromPrompt(prompt)
  if type(prompt) ~= "string" or prompt == "" then return nil end
  local name = prompt:match("^#([%w_]+)")
  if name and Fk.skill_skels and Fk.skill_skels[name] then return name end
  return nil
end

local function pickChoices(ai, data)
  local choices = data[1]
  if type(choices) ~= "table" or #choices == 0 then return nil end

  local minmax = data[3]
  local min_num = (type(minmax) == "table" and minmax[1]) or 1
  local max_num = (type(minmax) == "table" and minmax[2]) or 1
  local cancelable = data[4]
  local skill_name = data[5]
  local prompt = data[6]

  -- 同时机技能选择：全都挂上，不会亏
  if skill_name == "trigger" then
    local ret = {}
    for _, c in ipairs(choices) do
      if c ~= "Cancel" and #ret < max_num then table.insert(ret, c) end
    end
    if #ret >= min_num then return ret end
  end

  local scored = {}
  for _, c in ipairs(choices) do
    if c ~= "Cancel" then
      table.insert(scored, { c = c, s = scoreChoice(ai, c) })
    end
  end
  if #scored == 0 then return nil end

  table.sort(scored, function(a, b) return a.s > b.s end)

  -- 单选且全在亏：能取消就取消
  if cancelable and scored[1].s < 0 and max_num <= 1 then return {} end

  local ret = {}
  for _, item in ipairs(scored) do
    if #ret >= max_num then break end
    if item.s > 0 or #ret < min_num then table.insert(ret, item.c) end
  end

  if #ret < min_num then
    for i = #ret + 1, min_num do
      if scored[i] then table.insert(ret, scored[i].c) end
    end
  end

  if #ret == 0 then return nil end
  return ret
end

--- 判断这次选择该不该由我们接管
local function shouldHandleChoice(ai, data)
  local skill_name = data[5]
  if type(skill_name) ~= "string" or skill_name == "" then
    skill_name = skillFromPrompt(data[6])
  end

  if skill_name and Fk.skill_skels and Fk.skill_skels[skill_name] then
    local ok, ret = inScope(skill_name, Fk.skill_skels[skill_name])
    if ok and ret then return true end
  end

  -- 同时机多技能选择：选项是技能名，只要有一个归我们管就接
  if skill_name == "trigger" then
    for _, c in ipairs(data[1] or {}) do
      local cand = tostring(c):match("([%w_]+)$")
      if cand and Fk.skill_skels and Fk.skill_skels[cand] then
        local oks, hit = inScope(cand, Fk.skill_skels[cand])
        if oks and hit then return true end
      end
    end
    return false
  end

  -- 认不出技能时保守处理：只在选项差距明显时接管
  local choices = data[1]
  if type(choices) ~= "table" or #choices < 2 then return false end
  local best, worst
  for _, c in ipairs(choices) do
    local s = scoreChoice(ai, c)
    best = (not best or s > best) and s or best
    worst = (not worst or s < worst) and s or worst
  end
  return best and worst and best >= 4 and (best - worst) >= 3
end

local function installChoiceHandler()
  if choice_installed then return end
  local SmartAI = _G.SmartAI
  if not SmartAI then return end
  choice_installed = true

  local old = SmartAI.handleAskForChoices
  function SmartAI:handleAskForChoices(data)
    local ok, ret = pcall(function()
      if type(data) ~= "table" then return nil end
      if not shouldHandleChoice(self, data) then return nil end
      return pickChoices(self, data)
    end)
    if ok and ret then return ret end
    if old then return old(self, data) end
    return nil
  end

  -- room:askToChoice 也走 AskForChoices，但老代码里还有 AskForChoice 的路径，一并接管
  local old_single = SmartAI.handleAskForChoice
  function SmartAI:handleAskForChoice(data)
    local ok, ret = pcall(function()
      if type(data) ~= "table" then return nil end
      local choices, _all, skill_name, prompt = table.unpack(data)
      if type(choices) ~= "table" or #choices < 2 then return nil end
      local name = skill_name
      if type(name) ~= "string" or name == "" then name = skillFromPrompt(prompt) end
      if not (name and Fk.skill_skels and Fk.skill_skels[name]) then return nil end
      local ok_scope, hit = inScope(name, Fk.skill_skels[name])
      if not (ok_scope and hit) then return nil end
      local picked = pickChoices(self, { choices, choices, { 1, 1 }, false, name, prompt })
      return picked and picked[1] or nil
    end)
    if ok and ret then return ret end
    if old_single then return old_single(self, data) end
    local choices = type(data) == "table" and data[1] or nil
    return type(choices) == "table" and choices[1] or nil
  end
end

-- ============================================================
-- 无懈可击：别见牌就打
-- ============================================================
--
-- 引擎原来的 handleAskForUseCard 对无懈只做两件事：
--   · 能算出收益就算一把，收益为负就打；
--   · 算不出来时，只要"目标"是友方就打。
-- 第二条会打出很荒唐的牌：友方自己用【无中生有】【五谷丰登】【桃】，目标是友方，
-- 于是 AI 拿无懈把自家人的好牌顶掉；敌人对敌人用牌时也一样乱交。
--
-- 这里按"这张牌对谁有利"重写，规则只有三条：
--   1. 出牌的人是友方 → 不打。他用的牌对自己人有利，顶掉纯亏；
--   2. 目标不是友方 → 不打。打敌人就去打，无懈留给自家；
--   3. 只有明确冲着友方来的锦囊才交：拆、顺、决斗、借刀、火攻、南蛮、万箭、乐、兵粮、闪电。
--      无中、五谷、桃、铁索这类是好事，认不出的也一律留着。

-- 对目标有利的锦囊：谁用都不该拿无懈去顶
local GOOD_TRICKS = {
  peach = true,
  ex_nihilo = true,       -- 无中生有
  god_salvation = true,   -- 桃园结义
  amazing_grace = true,   -- 五谷丰登
}

-- 明确冲着人来的锦囊
local HARMFUL_TRICKS = {
  dismantlement = true,   -- 过河拆桥
  snatch = true,          -- 顺手牵羊
  duel = true,            -- 决斗
  collateral = true,      -- 借刀杀人
  fire_attack = true,     -- 火攻
  savage_assault = true,  -- 南蛮入侵
  archery_attack = true,  -- 万箭齐发
  indulgence = true,      -- 乐不思蜀
  supply_shortage = true, -- 兵粮寸断
  lightning = true,       -- 闪电
}

--- 从 prompt 里拆出目标与牌名：#AskForNullification::<toId>:<牌名>
---                      或：#AskForNullificationWithoutTo:<fromId>::<牌名>
local function parseNullificationPrompt(prompt)
  if type(prompt) ~= "string" then return nil, nil, nil end
  local parts = {}
  for seg in (prompt .. ":"):gmatch("([^:]*):") do
    table.insert(parts, seg)
  end

  if parts[1] == "#AskForNullification" then
    return tonumber(parts[3]), nil, parts[4]
  elseif parts[1] == "#AskForNullificationWithoutTo" then
    return nil, tonumber(parts[2]), parts[4]
  end
  return nil, nil, nil
end

--- 这一次该不该打无懈
local function shouldNullify(ai, data)
  local me = ai.player
  local extra = (type(data[5]) == "table") and data[5] or {}

  local room = ai.room
  local function playerById(id)
    if type(id) ~= "number" then return nil end
    local ok, p = pcall(function() return room:getPlayerById(id) end)
    if ok then return p end
    return nil
  end

  local from = playerById(extra.effectFrom)
  local to = playerById(extra.effectTo)
  local card_name
  if type(extra.effectCardId) == "number" then
    local ok, c = pcall(function() return Fk:getCardById(extra.effectCardId) end)
    if ok and c then card_name = c.trueName or c.name end
  end

  local to_id, from_id, name_from_prompt = parseNullificationPrompt(data[3])
  if not to then to = playerById(to_id) end
  if not from then from = playerById(from_id) end
  if not card_name then card_name = name_from_prompt end

  local function isFriendOrMe(p)
    if not p then return false end
    if p == me then return true end
    local ok, r = pcall(function() return ai:isFriend(p) end)
    return ok and r
  end

  -- 1. 出牌的是友方：这张牌对自己人有利，顶掉只会亏
  if isFriendOrMe(from) then return false end

  -- 2. 打不到友方身上，跟自己没关系
  if not to then
    -- 拿不到目标（群体锦囊逐人询问时）：只在牌名明确有害时兜底打
    return card_name ~= nil and HARMFUL_TRICKS[card_name] == true and from ~= nil
  end
  if not isFriendOrMe(to) then return false end

  -- 3. 明确有害的交无懈；好事和认不出的都留着
  if HARMFUL_TRICKS[card_name] then return true end
  if GOOD_TRICKS[card_name] then return false end
  -- 牌名认不出但目标是我自己：保命优先
  return to == me
end

local function installNullificationHandler()
  if nullify_installed then return end
  local SmartAI = _G.SmartAI
  if not SmartAI or type(SmartAI.handleAskForUseCard) ~= "function" then return end
  nullify_installed = true

  local old = SmartAI.handleAskForUseCard
  function SmartAI:handleAskForUseCard(data)
    -- 只管国战 / 烽燧这类按势力分阵营的模式，别的模式原样交给引擎
    if type(data) == "table" and data[2] == "nullification" and isHegemonyMode(self) then
      local ok, ret = pcall(function()
        if not shouldNullify(self, data) then return "" end
        local ids = self:getEnabledCards()
        if type(ids) ~= "table" or #ids == 0 then return "" end
        self:selectCard(ids[1], true)
        return self:doOKButton()
      end)
      if ok and type(ret) == "string" then return ret end
      -- 判断或出牌出错时宁可不出，也别白扔一张无懈
      return ""
    end
    if old then return old(self, data) end
    return ""
  end
end

-- ============================================================
-- 出基本牌 / 普通锦囊时的目标：同一套势力规则
-- ============================================================
--
-- 主动技走上面的 thinkActive，而【杀】【决斗】【顺手牵羊】这类牌走引擎的
-- CardSkillStrategy:chooseTargets，只按模拟收益选人。
-- 这里在模拟收益上叠一层势力加权：同样收益，先打人多那一家的成员。
-- 加成的对象只有"敌方"，治疗/给牌的友方目标不受影响。

local card_target_hooked = false

local function installCardTargetHook()
  if card_target_hooked then return end
  local ok, mod = pcall(require, "ltk.server.ai.strategies.card_skill")
  if not ok or type(mod) ~= "table" then return end
  local klass = mod[1]
  if not klass or type(klass.chooseTargets) ~= "function" then return end
  card_target_hooked = true

  local old = klass.chooseTargets
  function klass:chooseTargets(ai)
    local okk, ret, val = pcall(function()
      if not isHegemonyMode(ai) then return old(self, ai) end

      local AIGameLogic = require "ltk.server.ai.logic"
      local logic = AIGameLogic:new(ai)
      local ctx = kingdomContext(ai)
      local card = ai:getSelectedCard()

      local best, best_val = nil, -100000
      for targets in self:searchTargetSelections(ai) do
        logic.benefit = 0
        logic:useCard({ from = ai.player, tos = targets, card = card })
        local v = logic.benefit or 0
        for _, p in ipairs(targets) do
          if p ~= ai.player and not ai:isFriend(p) then
            v = v + kingdomThreat(ctx, p) * 0.6
          end
        end
        if not best or v > best_val then
          best, best_val = targets, v
        end
      end
      return best or {}, best_val
    end)
    if okk then return ret, val end
    return old(self, ai)
  end
end

-- ============================================================
-- 安装
-- ============================================================

local function hasStrategy(skel, klass)
  local list = skel.ai_strategies and skel.ai_strategies[klass]
  return list ~= nil and #list > 0
end

local function installSkeleton(skel, stats, scope)
  if not skel or not skel.name then return end
  if type(skel.effect_spec_list) ~= "table" then return end

  local has_active, has_viewas, has_trigger = false, false, false
  for _, spec in ipairs(skel.effect_spec_list) do
    local key = spec[1]
    if key == "active" then
      has_active = true
    elseif key == "viewas" then
      has_viewas = true
    elseif type(key) == "string" and NON_TRIGGER_KEYS[key] then
      -- 状态技：不需要"是否发动"
    else
      has_trigger = true
    end
  end

  local prof = profileOf(skel.name, skel, nil)
  if not prof then return end

  local special = scope.special and scope.special[skel.name]
  local added = 0

  local want_active = has_active
    or (has_viewas and prof.viewas_kind ~= "defense"
        and prof.viewas_kind ~= "buff" and prof.viewas_kind ~= nil)

  if want_active and not hasStrategy(skel, AI.ActiveStrategy) then
    skel:addAI(AI.newActiveStrategy {
      use_priority = 50,
      think = function(strategy, ai)
        local p = profileOf(strategy.skill_name, skel, ai.player)
        if not p then return nil, -100 end
        if special and special.active then
          local ok, cards, score = pcall(special.active, p, ai)
          if ok and cards then return cards, score end
          return nil, -100
        end
        local ok, cards, score = pcall(thinkActive, p, ai)
        if ok and cards then return cards, score end
        return nil, -100
      end,
    })
    if has_viewas then
      stats.viewas = stats.viewas + 1
    else
      stats.active = stats.active + 1
    end
    added = added + 1
  end

  if has_trigger and not hasStrategy(skel, AI.InvokeStrategy) then
    skel:addAI(AI.newInvokeStrategy {
      think = function(strategy, ai)
        local p = profileOf(strategy.skill_name, skel, ai.player)
        if not p then return false end
        if special and special.invoke then
          local ok, ret = pcall(special.invoke, p, ai)
          if ok then return ret end
          return false
        end
        local ok, ret = pcall(thinkInvoke, p, ai)
        if ok then return ret end
        return false
      end,
    })
    stats.trigger = stats.trigger + 1
    added = added + 1
  end

  if added > 0 then
    stats.skills = stats.skills + 1
  end
end

--- 日志：这个版本的 fk.qInfo / fk.qWarning 只收一个拼好的字符串，
--- 直接传可变参数会报 "expected 1..1 args"，所以先自己 format 再传
local function log(level, fmt, ...)
  local msg = fmt
  if select("#", ...) > 0 then
    local ok, s = pcall(string.format, fmt, ...)
    msg = ok and s or tostring(fmt)
  end
  if type(msg) ~= "string" then msg = tostring(msg) end
  pcall(function() fk[level](msg) end)
end
M.log = log

local function installAll(scope)
  if not (Fk.skill_skels and Fk.Ltk and Fk.Ltk.AI) then return end

  local stats = { skills = 0, active = 0, viewas = 0, trigger = 0, error = 0 }
  for name, skel in pairs(Fk.skill_skels) do
    local ok, hit = pcall(scope.match, name, skel)
    if ok and hit then
      local ok2 = pcall(installSkeleton, skel, stats, scope)
      if not ok2 then stats.error = stats.error + 1 end
    end
  end

  if stats.skills > 0 then
    log("qInfo", "%s 已接管 %d 个技能（主动技 %d，转化技 %d，触发技 %d）",
      scope.tag, stats.skills, stats.active, stats.viewas, stats.trigger)
  end
  if stats.error > 0 then
    log("qWarning", "%s 有 %d 个技能注册策略失败，已跳过", scope.tag, stats.error)
  end

  installChoiceHandler()
  installNullificationHandler()
  installCardTargetHook()
  return stats
end

--- 场上各势力人数（只含已明置的活人），供专属策略复用
---@return table<string, number>, table @ 势力→人数、完整上下文
function M.kingdomCounts(ai)
  local ok, ctx = pcall(kingdomContext, ai)
  if not ok or not ctx then return {}, nil end
  return ctx.counts, ctx
end

--- 某个目标在"势力"维度值多少分，专属策略可以拿去做加权
function M.kingdomThreat(ai, p)
  local ok, s = pcall(function()
    return kingdomThreat(kingdomContext(ai), p)
  end)
  if ok and type(s) == "number" then return s end
  return 0
end

--- 注册一个包范围
---@param opts { tag: string, match: fun(name: string, skel: any): boolean }
function M.registerScope(opts)
  if type(opts) ~= "table" or type(opts.match) ~= "function" then return end
  if opts.enabled == false then return end

  for _, scope in ipairs(scopes) do
    if scope.tag == opts.tag then
      return installAll(scope)
    end
  end

  table.insert(scopes, opts)
  return installAll(opts)
end

--- 包加载完成后再装一遍：此时 Fk.skill_skels 才齐全
function M.hookPostLoad()
  if type(Fk.addPostLoadFunc) ~= "function" then return end
  pcall(function()
    Fk:addPostLoadFunc(function()
      for _, scope in ipairs(scopes) do
        local ok, err = pcall(installAll, scope)
        if not ok then
          log("qWarning", "%s postLoad 安装失败：%s", scope.tag, tostring(err))
        end
      end
    end)
  end)
end

M.profileOf = profileOf
M.inScope = inScope

-- 便于测试
M._internal = {
  scoreChoice = scoreChoice,
  pickChoices = pickChoices,
  thinkInvoke = thinkInvoke,
  cardCost = cardCost,
}

return M
