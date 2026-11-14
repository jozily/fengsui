-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- 烽燧燎原 · 智能 AI 补丁（独立文件，不改官方包、不改技能效果）
--
-- 烽燧三个子包 300+ 个技能文件里没有一条 addAI，国战包里也有大量技能缺策略。
-- 引擎的 SmartAI 找不到策略时：主动技不出、触发技一律答"不发动"、
-- 选择项退化成"选第一个"，于是人机拿到这些武将就只会出基本牌。
--
-- 策略本体在 packages/hegemony/pkg/hegemony_ai_core.lua：
--   · 主动技：按技能声明的牌数/目标数枚举，用敌友、血量、手牌、牌价打分；
--   · 转化技：读 viewas 的 pattern，判断这张牌是打人、救命还是纯防御；
--   · 触发技：默认发动，限定技/失血/弃光手牌/移除武将有各自的时机；
--   · 选择项：按收益关键词打分，替掉"永远选第一个"。
-- 本文件只负责"认领烽燧的技能"，外加几条通用的烽燧专属判断。
--
-- 关闭方式：把 M.enabled 置 false，或注释掉 packages/fengsui/init.lua 里的 require。

local Core = require "packages/hegemony/pkg/hegemony_ai_core"

local M = {
  enabled = true,
}

-- 优先看 skill 文件的加载路径（最准），路径拿不到时退回前缀
local PREFIXES = {
  "fengsui_",
  "heg__", "nos_heg__", "m_heg__", "ty_heg__", "ofl_heg__", "ol_heg__",
}

local function isFengsuiSkill(name, skel)
  local path = skel and skel.file_path
  if type(path) == "string" and path:find("packages/fengsui/", 1, true) then
    return true
  end
  if type(path) == "string" and path:find("packages/hegemony/", 1, true) then
    return false
  end

  if type(name) ~= "string" then return false end
  for _, prefix in ipairs(PREFIXES) do
    if name:sub(1, #prefix) == prefix then return true end
  end
  return false
end

-- ============================================================
-- 小工具
-- ============================================================

local function handNum(me)
  local ok, n = pcall(function() return me:getHandcardNum() end)
  if ok and type(n) == "number" then return n end
  return 0
end

local function handIds(me)
  local ok, ids = pcall(function() return me:getCardIds("h") end)
  if ok and type(ids) == "table" then return ids end
  return {}
end

local function equipNum(me)
  local ok, ids = pcall(function() return me:getCardIds("e") end)
  if ok and type(ids) == "table" then return #ids end
  return 0
end

local function trueNameOf(cid)
  local ok, card = pcall(function() return Fk:getCardById(cid) end)
  if not ok or not card then return nil end
  return card.trueName or card.name, card
end

--- 把"全部手牌当一张牌"的代价折算成分数
--- 张数只增加代价：一张牌也好五张牌也好，合出来的都是一张【决斗】，威力不变
local function dumpAllCost(me)
  local cost, has_peach = 0, false
  for _, cid in ipairs(handIds(me)) do
    local tn, card = trueNameOf(cid)
    if tn == "peach" then
      has_peach = true
      cost = cost + (me.hp <= 2 and 3.2 or 1.8)
    elseif tn == "jink" or tn == "nullification" then
      cost = cost + (me.hp <= 2 and 2.4 or 1.2)
    elseif tn == "analeptic" then
      cost = cost + 1
    elseif card and card.type == Card.TypeEquip then
      cost = cost + 0.9
    else
      cost = cost + 0.5
    end
  end
  return cost, has_peach
end

-- ============================================================
-- 逐技能的专属判断：通用启发式明显会打错的几个，单独写清楚
-- ============================================================

local SPECIAL = {
  -- 刘谌「战绝」：所有手牌合成一张【决斗】，打一名异势力角色。
  --
  -- 要点不在"手牌够不够"，而在这一刀打得中打不中：
  --   · 张数不加威力，只加代价 —— 所以手牌越少越该打，一张牌恰恰是最划算的时候；
  --   · 决斗里谁先接不上【杀】谁掉血，我看不到对方手牌，只能按"一张手牌三成是杀"估；
  --   · 我自己的装备区能抵一刀（但会把装备区清空），对方有装备也一样；
  --   · 打输的代价是自己掉 1 血，再赔上全部手牌，残血时不能赌。
  ["fengsui_heg__zhanjue"] = {
    active = function(_, ai)
      local me = ai.player

      local ok_used, used = pcall(function()
        return me:usedSkillTimes("fengsui_heg__zhanjue", Player.HistoryPhase)
      end)
      if ok_used and (used or 0) > 0 then return nil end

      local hand = handNum(me)
      if hand < 1 then return nil end

      local spend, has_peach = dumpAllCost(me)
      -- 1 血时把仅有的桃砸进决斗，输了既没桃也没命
      if me.hp <= 1 and has_peach then return nil end

      -- 装备区能当一刀【杀】接住，接完装备就空了
      local my_supply = equipNum(me) > 0 and 1 or 0

      local best, best_score
      for _, p in ipairs(ai:getEnabledTargets()) do
        if p ~= me and not ai:isFriend(p) then
          -- 对方手牌里的杀按每张三成估：p0 是一张都没有，p1 是恰好一张
          -- （技能代码里只有持有〖战绝〗的自己能把装备区当杀，对方不行，所以只算手牌）
          local their_hand = handNum(p)
          local p0 = 0.65 ^ their_hand
          local p1 = their_hand * 0.35 * (0.65 ^ (their_hand - 1))

          -- 决斗里谁先接不上【杀】谁掉血：对方要打出比我多一张杀才轮到我吃亏
          local danger
          if my_supply == 0 then
            danger = 1 - p0
          else
            danger = math.max(0, 1 - p0 - p1)
          end
          danger = math.min(danger, 0.95)

          local gain
          if p.hp <= 1 then gain = 18         -- 收人头
          elseif p.hp == 2 then gain = 8
          else gain = 5 end
          local loss
          if me.hp <= 1 then loss = 30
          elseif me.hp == 2 then loss = 8
          elseif me.hp == 3 then loss = 5
          else loss = 3.5 end

          local s = (1 - danger) * gain - danger * loss
          s = s - spend
          -- 要靠装备区接刀时，赔进去的是整个装备区
          if my_supply > 0 then s = s - (1 - p0) * 1.5 end
          -- 砸出去的牌越多，这一张决斗越不划算
          s = s - math.max(0, hand - 2) * 0.7
          -- 同样打得中，先挑人多那个势力的人：决战里削大势力比削独苗要紧
          s = s + Core.kingdomThreat(ai, p) * 0.8

          if not best or s > (best_score or -1e9) then
            best, best_score = p, s
          end
        end
      end

      if not best or (best_score or 0) < 1.5 then return nil end
      return { {}, { best } }, best_score
    end,
  },

  -- 刘谌「烈荧」：限定技，全场一次，掉 1 血让这张牌无法被响应。
  -- 通用规则是"受伤了才交限定技"，这个技能恰恰要在血够的时候抢节奏；
  -- 但 1 血时等于自尽，2 血时得手里有桃、或者对面有残血可收才值得。
  ["fengsui_heg__lieying"] = {
    invoke = function(_, ai)
      local me = ai.player
      if me.hp <= 1 then return false end
      if me.hp >= 3 then return true end

      local ok, players = pcall(function() return ai.room.alive_players end)
      if ok and type(players) == "table" then
        for _, p in ipairs(players) do
          if p ~= me and p.hp <= 1 and not ai:isFriend(p) then return true end
        end
      end
      for _, cid in ipairs(handIds(me)) do
        if trueNameOf(cid) == "peach" then return true end
      end
      return false
    end,
  },
}

function M.install()
  if not M.enabled then return end
  return Core.registerScope {
    tag = "[fengsui-ai]",
    match = isFengsuiSkill,
    special = SPECIAL,
  }
end

-- 包加载完成后统一安装：此时 Fk.skill_skels 才齐全
Core.hookPostLoad()

-- 热重载时技能可能已经在了，先试一次；重复调用是幂等的
if Fk.skill_skels and next(Fk.skill_skels) then
  local ok, err = pcall(M.install)
  if not ok then
    Core.log("qWarning", "[fengsui-ai] 预安装失败：%s", tostring(err))
  end
end

M.profileOf = Core.profileOf

return M
