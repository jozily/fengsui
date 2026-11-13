-- 左慈〖役鬼〗/〖汲魂〗在烽燧燎原内的界面与规则替代。
--
-- 设计约束：只在 fengsui 包被加载时生效；没有导入 fengsui 时，官方
-- hegemony 的 ld__yigui / ld__jihun 以及 YiGuiInteraction.qml 完全保持原样。
-- 因此不改 packages/hegemony 任何文件，全部通过 Package.install 之后对
-- 已编译技能对象做运行时替换（与 official_overrides.lua 同一套机制）。
--
-- 三处改动：
-- 1. 原版要把「万能牌堆」里的一堆实体牌摆出来供点选，这里改成符会/浮邈
--    那种「牌名」选择框；魂与牌名合在同一个 custom 交互里，用
--    "魂名|牌名" 一个字符串回传，viewAs 解析后印虚拟牌。
-- 2. 魂的势力栏：原版「双势力」一栏改称「其他」，收纳双势力/中立者/
--    野心家魂；中立者魂可在任意势力栏（野心家栏除外）选中，且视为使用时
--    可指定任意势力的角色为目标，野心家与未确定势力也在其内。
-- 3. 其余官方逻辑（明置得魂、PreCardUse 消耗魂、每回合牌名限一次、
--    扇子杀备份魂信息）一概不动，仍由官方技能对象负责。

local U = require "packages.utility.utility"

local M = {}

local YIGUI = "ld__yigui"
local HUN = "&ld__hun"
local NEUTRAL = "fengsui_neutral"
local LEGACY_NEUTRAL = "fengsui_neutral_old"
local KINGDOMS = { "wei", "shu", "wu", "qun", "jin" }

Fk:loadTranslationTable {
  ["#fengsui_yigui-card"] = "役鬼：选择要视为使用的牌名",
  ["#fengsui_yigui-soul"] = "役鬼：选择要移去的「魂」",
}

---------------------------------------------------------------------------
-- 魂的势力归属与目标规则
---------------------------------------------------------------------------

local function isNeutralSoul(name)
  local g = Fk.generals[name]
  return g ~= nil and (g.kingdom == NEUTRAL or g.kingdom == LEGACY_NEUTRAL)
end

--- 一张「魂」应当出现在势力选择框的哪些栏里。
--- 其他 = 双势力 / 中立者 / 野心家（原「双势力」栏改称「其他」）。
--- 中立者魂同时可归入魏蜀吴群晋各栏，唯独不进野心家栏。
local function soulTabKeys(name)
  local g = Fk.generals[name]
  if not g then return { "other" } end
  local k, sub = g.kingdom, g.subkingdom
  local tabs = {}
  if k == NEUTRAL or k == LEGACY_NEUTRAL then
    for _, t in ipairs(KINGDOMS) do table.insert(tabs, t) end
    table.insert(tabs, "other")
  elseif k == "wild" then
    table.insert(tabs, "wild")
    table.insert(tabs, "other")
  else
    if table.contains(KINGDOMS, k) then table.insert(tabs, k) end
    if sub and table.contains(KINGDOMS, sub) and not table.contains(tabs, sub) then
      table.insert(tabs, sub)
    end
    -- 双势力与其他非常规势力一并归入「其他」。
    if sub or not table.contains(KINGDOMS, k) then table.insert(tabs, "other") end
  end
  return tabs
end

--- 该「魂」视为使用的牌能否指定 to 为目标。
--- 官方只认魂自身的 kingdom/subkingdom；这里给中立者魂放开到任意势力，
--- 野心家与未确定势力照旧可选。
local function canTargetbySoul(to, soul)
  local g = Fk.generals[soul]
  if not g then return false end
  local tokingdom = to.kingdom
  if tokingdom == "wild" and
      (to:getMark("hasShownMainGeneral") == 0 or to:getMark("__heg_wild") == 0) then
    tokingdom = to:getMark("__heg_init_kingdom")
  end
  if type(tokingdom) ~= "string" then tokingdom = "unknown" end
  if isNeutralSoul(soul) then
    return true
  end
  local kingdoms = {}
  table.insertIfNeed(kingdoms, g.kingdom)
  if g.subkingdom then table.insertIfNeed(kingdoms, g.subkingdom) end
  return tokingdom == "unknown" or table.contains(kingdoms, tokingdom)
end

--- 有合法目标的「魂」才可选（沿用官方对 fix/must/exclusive/include 的处理）。
local function getAvailableSouls(player)
  local souls = U.getPrivateMark(player, HUN)
  if #souls == 0 then return {} end
  local players, availables = {}, {}
  local extra_data = player:getTableMark("ld__yigui_extra_data")
  if extra_data.fix_targets then
    table.insertTableIfNeed(players, extra_data.fix_targets)
  elseif extra_data.must_targets then
    table.insertTableIfNeed(players, extra_data.must_targets)
  elseif extra_data.exclusive_targets then
    table.insertTableIfNeed(players, extra_data.exclusive_targets)
  elseif extra_data.include_targets then
    table.insertTableIfNeed(players, extra_data.include_targets)
  end
  if #players == 0 then
    players = Fk.currentRoom(player).alive_players
  else
    players = table.map(players, Util.Id2PlayerMapper)
  end
  for _, s in ipairs(souls) do
    if table.find(players, function(p) return canTargetbySoul(p, s) end) then
      table.insert(availables, s)
    end
  end
  return availables
end

local function allCardNames(player)
  local names = {}
  for _, id in ipairs(player:getTableMark("ld__yigui_cards")) do
    local card = Fk:getCardById(id)
    if card then table.insertIfNeed(names, card.name) end
  end
  return names
end

--- 某一张「魂」当前可以印哪些牌名。逻辑照搬官方 getAvailableYiguiCard，
--- 只是把 souls 固定为单张，并且目标限制走上面的 canTargetbySoul。
local function availableCardNames(player, soul)
  local card_names = allCardNames(player)
  if #card_names == 0 then return {} end
  local ban_cards = player:getTableMark("ld__yigui_useds-turn")
  table.insertTableIfNeed(ban_cards, { "jink", "nullification", "heg__nullification" })
  local extra_data = player:getTableMark("ld__yigui_extra_data")
  local names = {}
  for _, name in ipairs(card_names) do
    local card = Fk:cloneCard(name)
    if (Fk.currentResponsePattern == nil or
        Exppattern:Parse(Fk.currentResponsePattern):match(card)) and
        not table.contains(ban_cards, card.trueName) then
      card.skillName = YIGUI
      card:setMark("ld__yigui", soul)
      if player:canUse(card, extra_data) and not player:prohibitUse(card) then
        local min_target = card.skill:getMinTargetNum(player)
        if min_target > 0 then
          for _, p in ipairs(Fk.currentRoom(player).alive_players) do
            if card.skill:targetFilter(player, p, {}, {}, card, extra_data) then
              table.insertIfNeed(names, name)
              break
            end
          end
        else
          table.insertIfNeed(names, name)
        end
      end
    end
  end
  return names
end

---------------------------------------------------------------------------
-- 交互框：魂 + 牌名，两份数据打包成一个字符串回传
---------------------------------------------------------------------------

--- 交互数据一律摊平成「字符串数组 + 平行数组」，不传嵌套表。
--- 嵌套表在 cbor/QVariant 之间来回转换时，空表、混合键都可能掉成对象，
--- 到 QML 里 Array.isArray 判假，按钮就会一直是灰的。
local function buildInteraction(skill, player)
  local souls = U.getPrivateMark(player, HUN)
  local availables = getAvailableSouls(player)
  if #availables == 0 then return end
  local soulTabs = {}
  for _, s in ipairs(souls) do
    table.insert(soulTabs, table.concat(soulTabKeys(s), ","))
  end

  -- 魂按钮上的文字也在 Lua 侧算好，省得 QML 再去查武将数据。
  local soulLabels = {}
  for _, s in ipairs(souls) do
    local g = Fk.generals[s]
    local k = g and g.kingdom or ""
    local kingdom
    if k == "jin" then kingdom = "晋"
    elseif k == "wild" then kingdom = "野"
    elseif k ~= "" then kingdom = Fk:translate(k) end
    local label = Fk:translate(s)
    if type(label) ~= "string" then label = s end
    if type(kingdom) == "string" and kingdom ~= "" then
      label = kingdom .. "|" .. label
    end
    table.insert(soulLabels, label)
  end

  -- cardKeys[i] = "魂|牌名"，cardNames[i] 为同位置的可读牌名；
  -- 同一牌名只保留一张（取第一个能印它的魂），避免按钮重复。
  local cardKeys, cardNames, seen = {}, {}, {}
  for _, s in ipairs(availables) do
    for _, name in ipairs(availableCardNames(player, s)) do
      if not seen[name] then
        seen[name] = true
        table.insert(cardKeys, s .. "|" .. name)
        table.insert(cardNames, name)
      end
    end
  end

  return {
    type = "custom",
    qml = {
      url = "packages/fengsui/qml/FengsuiYiguiInteraction.qml",
      prop = {
        skillName = YIGUI,
        souls = souls,
        soulLabels = soulLabels,
        availableSouls = availables,
        allCardNames = allCardNames(player),
        cardKeys = cardKeys,
        cardNames = cardNames,
        soulTabs = soulTabs,
      },
    },
  }
end

local function parseAnswer(data)
  if type(data) ~= "string" then return end
  local soul, name = data:match("^([^|]+)|([^|]+)$")
  if not soul or not name or not Fk.all_card_types[name] then return end
  return soul, name
end

---------------------------------------------------------------------------
-- 运行时替换
---------------------------------------------------------------------------

function M.apply()
  local skill = Fk.skills and Fk.skills[YIGUI]
  -- 官方技能在 hegemony 包 install 之后才编译好；未编译或已替换则跳过。
  if not skill or type(skill.viewAs) ~= "function" or
      type(skill.cardFilter) ~= "function" or skill.__fengsui_yigui_ui then
    return
  end

  -- interaction 必须是可带字段的表（引擎会写 .data / .spec），用 __call
  -- 的表替换掉骨架编译时捕获的官方闭包。
  skill.interaction = setmetatable({}, {
    __call = function(_, self, player) return buildInteraction(self, player) end,
  })
  -- 不再展开万能牌堆、不再要求点选实体牌。
  skill.cardFilter = Util.FalseFunc
  skill.expand_pile = nil
  skill.visible_pile = nil
  skill.viewAs = function(self, player, cards)
    if #cards > 0 then return end
    local soul, name = parseAnswer(self.interaction and self.interaction.data)
    if not soul then return end
    if not table.contains(U.getPrivateMark(player, HUN), soul) then return end
    local card = Fk:cloneCard(name)
    card.skillName = YIGUI
    card:setMark("ld__yigui", soul)
    return card
  end
  skill.enabledAtPlay = function(self, player)
    return self:isEffectable(player) and #getAvailableSouls(player) > 0
  end
  skill.enabledAtResponse = function(self, player, cardResponsing)
    if cardResponsing then return false end
    return self:isEffectable(player) and #getAvailableSouls(player) > 0
  end

  -- 目标限制：官方 prohibit 效果里的 canbeTargetedbySoul 已被编译进
  -- isProhibited，整体换成带中立者规则的版本，保留扇子杀的备用信息。
  local skel = Fk.skill_skels and Fk.skill_skels[YIGUI]
  for _, effect in ipairs(skel and skel.effects or {}) do
    if type(effect.isProhibited) == "function" and
        not effect.__fengsui_yigui_prohibit then
      effect.isProhibited = function(self, from, to, card)
        if not card or not table.contains(card.skillNames or {}, YIGUI) then return end
        local general = card:getMark("ld__yigui")
        if not general and RoomInstance then
          local logic = RoomInstance.logic
          local event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
          if event then
            local use = event.data
            if table.contains(use.card.skillNames, YIGUI) and
                use.card.name == card.name then
              use.extra_data = use.extra_data or {}
              general = use.extra_data.ce_hc__yigui
            end
          end
        end
        if general then return not canTargetbySoul(to, general) end
      end
      effect.__fengsui_yigui_prohibit = true
    end
  end

  skill.__fengsui_yigui_ui = true
  fk.qInfo("[fengsui-zuoci] ld__yigui 已切换到牌名式选择框")
end

return M
