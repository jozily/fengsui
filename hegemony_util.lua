local modern = require "packages.hegemony.util"

local compat = setmetatable({}, { __index = modern })

-- 遴哲：被标记的角色除计算胜利外，视为与标记者势力相同。
-- 与官方「构逆」同构：第四参数 ignore_gouni 是官方留给胜利／投降计算的开关，
-- 这里复用它一并跳过遴哲。不再用 debug 栈去猜调用来源——栈层级会因为
-- compareExpectedKingdomWith 的间接调用而偏一层，且 fengsui 模式自己的
-- winner_getter 在 fengsuihegemony.lua，根本不在原先写死的识别名单里。
local linzheMark = "fengsui_heg__linzhe_target"
local _compareKingdomWith = modern.compareKingdomWith
local _compareExpectedKingdomWith = modern.compareExpectedKingdomWith

function compat.compareKingdomWith(from, to, diff, ignore_gouni)
  if not ignore_gouni and from and to and from ~= to and
    from.getTableMark and to.getTableMark then
    if table.contains(from:getTableMark(linzheMark), to) or
      table.contains(to:getTableMark(linzheMark), from) then
      local ret = true
      if diff then ret = not ret end
      return ret
    end
  end
  return _compareKingdomWith(from, to, diff, ignore_gouni)
end
-- 全局生效：hegemony 本体与各包都直接调用 HegUtil.compareKingdomWith，
-- 必须替换模块表上的函数，仅包装 compat 只对 fengsui 包内生效。
modern.compareKingdomWith = compat.compareKingdomWith

-- 官方 compareExpectedKingdomWith 内部直接调用 compareKingdomWith(from, to)，
-- 不会透传第四参数；这里在「显式要求忽略」时按官方同样的流程走一遍，
-- 让胜利计算能把 ignore 传到底。没传 ignore 的调用仍完全交给官方实现，
-- 因此选将、敌友判断等场合的遴选效果不受影响。
function compat.compareExpectedKingdomWith(from, to, diff, ignore_gouni)
  if ignore_gouni == nil then
    return _compareExpectedKingdomWith(from, to, diff)
  end
  local room = Fk:currentRoom()
  if from == to then return not diff end
  if compat.compareKingdomWith(from, to, false, ignore_gouni) then
    return not diff
  end
  if to.kingdom == "unknown" then return not diff end
  if from.kingdom == "unknown" then
    local kingdom = from:getMark("__heg_kingdom")
    local i = 1
    local lord = false
    for _, p in ipairs(room.players) do
      if modern.getKingdom(p) == kingdom then
        i = i + 1
        if string.find(p.general, "lord") then lord = true end
      end
    end
    if i > #room.players // 2 and not lord then
      return diff
    elseif kingdom == modern.getKingdom(to) then
      return not diff
    end
  end
  return diff
end
modern.compareExpectedKingdomWith = compat.compareExpectedKingdomWith

compat.HegMarkChanged = TriggerEvent:subclass("FengsuiHegMarkChanged")
-- Fengsui 奖惩即将执行时；替换摸牌和弃牌两种分支，保留死亡的其他后续。
compat.KillRewardExecuting = TriggerEvent:subclass("FengsuiKillRewardExecuting")

-- 怀香、绝嗣把势力暂时显示为未确定，但击杀奖惩仍使用原势力。
function compat.getRewardKingdom(player)
  if not player then return "unknown" end
  if player.kingdom == "unknown" then
    local original = player:getMark("fengsui_heg__huaixiang_original_kingdom-turn")
    if type(original) ~= "string" or original == "" then
      original = player:getMark("fengsui_heg__juesi_original_kingdom")
    end
    if type(original) == "string" and original ~= "" then return original end
  end
  return compat.getKingdom(player)
end

function compat.compareRewardKingdom(first, second)
  return compat.getRewardKingdom(first) == compat.getRewardKingdom(second)
end

if not modern.__fengsui_mark_hooked then
  local addHegMark = modern.addHegMark
  modern.addHegMark = function(player, markName, number)
    local result = addHegMark(player, markName, number)
    if player and player.room and player.room.logic then
      player.room.logic:trigger(compat.HegMarkChanged, player, {
        markName = markName,
        number = number or 1,
        action = "gain",
      })
    end
    return result
  end
  modern.__fengsui_mark_hooked = true
end

-- Fengsui's hegemony rule passes room explicitly; the 0.5.20 helper only needs player.
function compat.addHegMark(roomOrPlayer, playerOrMark, markOrNumber, number)
  if type(playerOrMark) == "string" then
    local player, mark, n = roomOrPlayer, playerOrMark, markOrNumber or 1
    if mark == "fengsui_heg_ascend" or mark == "fengsui_heg__descend" then
      local room = player.room
      local key = mark == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or "@!!fengsui_heg__descend"
      local skill = mark == "fengsui_heg_ascend" and "fengsui_heg_ascend_skill&" or "fengsui_heg__descend_skill&"
      room:addPlayerMark(player, key, n)
      room:handleAddLoseSkills(player, skill)
      if room.logic then room.logic:trigger(compat.HegMarkChanged, player, {
        markName = mark, number = n, action = "gain",
      }) end
      return
    end
    return modern.addHegMark(roomOrPlayer, playerOrMark, markOrNumber)
  end
  if markOrNumber == "fengsui_heg_ascend" or markOrNumber == "fengsui_heg__descend" then
    local player, mark, n = playerOrMark, markOrNumber, number or 1
    local room = player.room
    local key = mark == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or "@!!fengsui_heg__descend"
    local skill = mark == "fengsui_heg_ascend" and "fengsui_heg_ascend_skill&" or "fengsui_heg__descend_skill&"
    room:addPlayerMark(player, key, n)
    room:handleAddLoseSkills(player, skill)
    if room.logic then room.logic:trigger(compat.HegMarkChanged, player, {
      markName = mark, number = n, action = "gain",
    }) end
    return
  end
  return modern.addHegMark(playerOrMark, markOrNumber, number)
end

function compat.removeHegMark(room, player, markName, number)
  local amount = number or 1
  local key = markName == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or
    markName == "fengsui_heg__descend" and "@!!fengsui_heg__descend" or
    "@!!" .. markName
  local before = player and player:getMark(key) or 0
  if markName == "fengsui_heg_ascend" or markName == "fengsui_heg__descend" then
    local key = markName == "fengsui_heg_ascend" and "@!!fengsui_heg_ascend" or "@!!fengsui_heg__descend"
    local skill = markName == "fengsui_heg_ascend" and "fengsui_heg_ascend_skill&" or "fengsui_heg__descend_skill&"
    room:removePlayerMark(player, key, amount)
    if player:getMark(key) == 0 then room:handleAddLoseSkills(player, "-" .. skill) end
  else
    modern.removeHegMark(room, player, markName, amount)
  end
  local used = math.min(before, amount)
  if used > 0 and room.logic then
    room.logic:trigger(compat.HegMarkChanged, player, {
      markName = markName, number = -used, action = "use",
    })
  end
end

-- 本局变更过的武将牌不能再次作为变更副将或合璧候选；场上暗置的
-- 武将牌也视为已占用，不能因为暂时看不见而再次选入。
local transformedGeneralsTag = "fengsui_heg__transformed_generals"

local function wasTransformed(room, general)
  local used = room:getTag(transformedGeneralsTag) or {}
  return used[general] == true
end

local function recordTransformed(room, general)
  if not general or general == "" or general == "anjiang" then return end
  local used = room:getTag(transformedGeneralsTag) or {}
  used[general] = true
  room:setTag(transformedGeneralsTag, used)
end

compat.recordTransformed = recordTransformed

local function isGeneralOnField(room, general)
  for _, p in ipairs(room.players) do
    if p.general == general or p.deputyGeneral == general or
        p:getMark("__heg_general") == general or p:getMark("__heg_deputy") == general then
      return true
    end
  end
  return false
end

local function findFreshGenerals(room, kingdom, num)
  return room:findGenerals(function(name)
    local general = Fk.generals[name]
    if not general or wasTransformed(room, name) or isGeneralOnField(room, name) then return false end
    if kingdom == "wild" then
      return general.kingdom ~= "wild" and general.subkingdom ~= "wild"
    end
    return general.kingdom == kingdom or general.subkingdom == kingdom
  end, num)
end

-- 特殊身份势力，与 fengsuihegemony.lua 生成 allKingdoms 时的排除项一致：
-- wild（野心家）、fengsui_neutral / fengsui_neutral_old（中立者）都不是
-- 可选「势力」。既用于「野心家副将」的不限势力候选池，也用于合璧候选池
-- 的上层规则排除。
local specialKingdoms = {
  wild = true,
  fengsui_neutral = true,
  fengsui_neutral_old = true,
}

-- 「野心家副将」规则专用候选池：不限势力，但排除上面的特殊身份武将牌。
-- 单独成函数，不改 findFreshGenerals 的既有语义——非野心家的变更副将
-- 路径与改动前完全相同。
local function findAnyKingdomGenerals(room, num)
  return room:findGenerals(function(name)
    local general = Fk.generals[name]
    return general and not wasTransformed(room, name) and
      not isGeneralOnField(room, name) and
      not specialKingdoms[general.kingdom] and
      not specialKingdoms[general.subkingdom]
  end, num)
end

-- 野心家身份：涵盖「wild 势力武将野心家」「君主死亡变野」「群雄割据 1/3 转野」
-- 三类。只看 __heg_kingdom 会漏判——前两类里该标记可能仍是常规势力。
function compat.isWildPlayer(player)
  if not player then return false end
  if player.kingdom == "wild" or player.role == "wild" then return true end
  if player:getMark("__heg_kingdom") == "wild" or
      player:getMark("__heg_init_kingdom") == "wild" then return true end
  for _, m in ipairs({ "__heg_wild", "__heg_join_wild", "__heg_construct_wild", "_wild_gained" }) do
    if (tonumber(player:getMark(m)) or 0) > 0 then return true end
  end
  return false
end

-- The official helper is already random when it receives one candidate. For
-- Fengsui callers that request a multi-candidate choice, keep the same pool
-- and event contract but select one candidate directly.
function compat.transformGeneral(room, player, isMain, isHidden, num, skillName)
  local data = modern.GeneralTransformedData:new{
    isMain = isMain,
    isHidden = isHidden,
    num = num,
    skillName = skillName,
  }
  if room.logic:trigger(modern.GeneralTransforming, player, data) then return false end
  isMain, isHidden = data.isMain, data.isHidden
  local original = isMain and player.general or player.deputyGeneral
  data.origName = original
  if not original then return false end
  if original == "anjiang" then
    player:revealGeneral(not isMain, true)
    original = isMain and player.general or player.deputyGeneral
    data.origName = original
  end

  local kingdom = player:getMark("__heg_kingdom")
  if kingdom == 0 or kingdom == "" or kingdom == nil then kingdom = player.kingdom end
  local count = math.max(1, num or 1)

  -- 规则「野心家副将」：野心家变更副将时，从将池中随机抽取一张任意势力
  -- 的武将直接变更，不受自身势力限制，也不看 num（本包所有换副将本来就是
  -- 随机给一张）。不改 __heg_kingdom 等标记，否则会污染胜负结算与奖惩。
  local wildDeputy = not isMain and compat.isWildPlayer(player)
  local generals
  if wildDeputy then
    -- 先把全部合法候选抽出，再真随机取一张；未被选中的必须完整归还
    -- 将池，否则后续所有人都会无将可变更。
    local pool = findAnyKingdomGenerals(room, #(room.general_pile or {}))
    if #pool == 0 then return false end
    generals = { room:tableRandomPick(pool, 1)[1] }
    local rest = {}
    for _, g in ipairs(pool) do
      if g ~= generals[1] then table.insert(rest, g) end
    end
    if #rest > 0 then room:returnToGeneralPile(rest) end
    -- 供模式规则技能发日志；不改 data.num，保持变更事件的原契约。
    data.fengsuiWildDeputy = true
  else
    generals = findFreshGenerals(room, kingdom, count)
  end
  if #generals == 0 then return false end
  -- num 的含义是「备选几张」，最终只会换上一张，因此这里必须按 n = 1 询问。
  -- Room:askToChooseGeneral 在 n > 1 时返回的是被选武将组成的数组（#generals == n
  -- 时直接返回整个 generals），若照旧把返回值当武将名传给 changeHero，会把一个
  -- 数组写进 general / deputyGeneral 属性，随后 ChangeProperty 里
  -- Fk.generals[数组] 取到 nil 直接崩服（清殇、陈笃等传 3 的技能都会踩到）。
  local general
  if wildDeputy or #generals == 1 then
    general = generals[1]
  else
    general = room:askToChooseGeneral(player, {
      generals = generals,
      n = 1,
      no_convert = true,
    })
    -- 兜底：即使上层改了选将规则返回数组，也只取第一张，绝不把表写进属性。
    if type(general) == "table" then general = general[1] end
  end
  if not general or type(general) ~= "string" then
    room:returnToGeneralPile(generals)
    return false
  end
  table.removeOne(generals, general)
  if #generals > 0 then room:returnToGeneralPile(generals) end

  room:changeHero(player, general, false, not isMain, not isHidden, false, false)
  if isHidden then
    player:hideGeneral(not isMain)
    room:sendLog{
      type = "#ChangeHiddenGeneral",
      from = player.id,
      arg = isMain and "mainGeneral" or "deputyGeneral",
      toast = true,
    }
  end
  room:setPlayerMark(player, isMain and "__heg_general" or "__heg_deputy", general)
  recordTransformed(room, data.origName)
  recordTransformed(room, general)
  room.logic:trigger(modern.GeneralTransformed, player, data)
  return true
end

local function returnGenerals(room, generals, chosen)
  table.removeOne(generals, chosen)
  if #generals > 0 then room:returnToGeneralPile(generals) end
end

local function changeGeneral(room, player, general, isMain, isHidden, data)
  room:changeHero(player, general, false, not isMain, not isHidden, false, false)
  if isHidden then
    player:hideGeneral(not isMain)
    room:sendLog{
      type = "#ChangeHiddenGeneral",
      from = player.id,
      arg = isMain and "mainGeneral" or "deputyGeneral",
      toast = true,
    }
  end
  room:setPlayerMark(player, isMain and "__heg_general" or "__heg_deputy", general)
  recordTransformed(room, data.origName)
  recordTransformed(room, general)
  room.logic:trigger(modern.GeneralTransformed, player, data)
end

function compat.askToHebiOrTransform(room, player, skillName, cancelable)
  if not room or not player or player.dead then return false end
  local main = Fk.generals[modern.getActualGeneral(player, false)]
  if not main then return compat.transformGeneral(room, player, false, false, 1, skillName) end

  -- 合璧候选池：配对对象只能是常规势力武将。野心家势力武将只能做主将
  -- （野心家角色只能做主将），中立者是特殊身份而非可选势力；按上层
  -- 规则「野心家不可与中立者或另一野心家配对」一并从池中排除。
  -- 主将本身是野心家势力武将时同样按此池合璧：其珠联璧合对象均为常规
  -- 势力，不受排除影响；无可用配对对象时仍回落到变更副将。
  local companions = room:findGenerals(function(name)
    local general = Fk.generals[name]
    return general and not wasTransformed(room, name) and not isGeneralOnField(room, name) and
      not specialKingdoms[general.kingdom] and not specialKingdoms[general.subkingdom] and
      (main:isCompanionWith(general) or general:isCompanionWith(main))
  end, #(room.general_pile or {}))

  -- A careerist companion cannot form Hebi; replace the deputy directly instead.
  if #companions == 0 then
    return compat.transformGeneral(room, player, false, false, 1, skillName)
  end

  local choices = { "fengsui_hebi_choice" }
  if cancelable then table.insert(choices, "Cancel") end
  local choice = room:askToChoice(player, {
    choices = choices,
    skill_name = skillName,
    prompt = "#fengsui-hebi-or-transform",
  })
  if choice ~= "fengsui_hebi_choice" then
    room:returnToGeneralPile(companions)
    if choice == "Cancel" then return false end
    return compat.transformGeneral(room, player, false, false, 1, skillName)
  end

  local original = modern.getActualGeneral(player, true)
  local data = modern.GeneralTransformedData:new{
    isMain = false,
    isHidden = false,
    num = #companions,
    origName = original,
    skillName = skillName,
  }
  if room.logic:trigger(modern.GeneralTransforming, player, data) then
    room:returnToGeneralPile(companions)
    return false
  end
  if player.deputyGeneral == "anjiang" then player:revealGeneral(true, true) end

  local general = room:tableRandomPick(companions, 1)[1]
  if not general or general == "" then
    room:returnToGeneralPile(companions)
    return false
  end
  returnGenerals(room, companions, general)
  changeGeneral(room, player, general, false, false, data)
  modern.addHegMark(player, "companion", 1)
  return true
end

-- 非标签技判定：供揖门访客、相谶发放等临时获得技能的场合使用。
-- 主将技/副将技是位置标签而非技能类型，不在排除之列（由调用方做位置匹配）。
local GRANT_FORBIDDEN_TAGS = {
  [Skill.Lord] = true, [Skill.Compulsory] = true, [Skill.Limited] = true,
  [Skill.Wake] = true, [Skill.Switch] = true, [Skill.Quest] = true,
  [Skill.Permanent] = true, [Skill.Hidden] = true, [Skill.AttachedKingdom] = true,
  [Skill.Charge] = true, [Skill.Family] = true, [Skill.Combo] = true,
  [Skill.Rhyme] = true, [Skill.Force] = true,
}

function compat.isTaggedSkill(skill)
  if not skill then return true end
  local skel = skill.getSkeleton and skill:getSkeleton() or skill
  for _, tag in ipairs(skel.tags or {}) do
    if GRANT_FORBIDDEN_TAGS[tag] then return true end
  end
  return false
end

Fk:loadTranslationTable{
  ["#fengsui-hebi-or-transform"] = "请选择合璧；若无可用配对对象则自动变更副将",
}

return compat
