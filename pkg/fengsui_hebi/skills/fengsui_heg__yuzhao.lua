-- 张裕【虞照】（旧版【相谶】按原名留在 fengsui_heg__xiangchen.lua 作存档）
--
-- 当一名同势力的角色体力值变化后，你可以观看剩余武将池中与其勾玉相同的
-- 三张武将牌并令其获得其中一个非标签技直至其回合结束（称为“谶”，
-- 若已有“谶”则改为替换，其失去“谶”后摸一张牌）。
--
-- 与旧版的区别：候选只按目标勾玉筛三张（不再看当前回合角色势力、不再按
-- 势力人数决定张数）；同时至多保留一个“谶”，替换时可在看完武将牌后取消。
--
-- 「谶」是临时挂到角色身上的技能，不对应任何一张武将牌。因此排除两类技能：
-- 位置标签技（主将技/副将技），以及会主动明置、暗置、变更、移除武将牌的技能。
-- 仅把「明置此武将牌」之类当作条件或时机的技能（如【望归】）不受影响。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.utility.utility"

local yuzhao = fk.CreateSkill { name = "fengsui_heg__yuzhao" }

local chan_mark = "fengsui_heg__yuzhao_chan"         -- 当前「谶」的技能名
local wait_mark = "fengsui_heg__yuzhao_wait"         -- 待该角色自己的结束阶段回收
local history_mark = "fengsui_heg__yuzhao_history"   -- 曾获得过的技能，避免重复

local function forbidden(general)
  return not general or general.kingdom == "wild" or
    general.kingdom == "fengsui_neutral_old" or general.kingdom == "fengsui_neutral"
end

local function fieldGeneralsAndSkills(room)
  local generals, skills = {}, {}
  for _, p in ipairs(room.players) do
    for _, is_deputy in ipairs({ false, true }) do
      local name = H.getActualGeneral(p, is_deputy)
      if name and name ~= "" and name ~= "anjiang" then
        generals[name] = true
        local general = Fk.generals[name]
        if general then
          for _, skill_name in ipairs(general:getSkillNameList(true)) do
            skills[skill_name] = true
          end
        end
      end
    end
  end
  return generals, skills
end

-- 描述里这些说法只是把武将牌状态当作条件或时机，技能本身并不改变武将牌，
-- 也不会去引用「技能所在的那张武将牌」。先把它们摘掉，再判断有无改牌动作，
-- 否则「仅明置此武将牌」会因为含有「明置此武将牌」而误剔除【望归】这一类。
local CONDITIONAL_PHRASES = {
  -- 「仅/首次/…明置…武将牌后」这类整句先摘干净，否则剩下的「明置一张
  -- 武将牌」会被下面的动作短语误认（如【孤茹】【连徙】【入洛】【趋势】）。
  "变更副将后", "移除副将后",
  "仅明置一张武将牌", "仅暗置一张武将牌",
  "首次明置武将牌后", "明置武将牌后",
  "明置一张武将牌后", "暗置一张武将牌后",
  "已明置武将牌数", "明置武将牌数",
  "当一名角色明置或暗置武将牌后",
  "当你明置此武将牌或即将暗置此武将牌时",
  "当你首次明置此武将牌后", "当你首次明置此武将牌时",
  "当你明置此武将牌后", "当你明置此武将牌时",
  "当你暗置此武将牌后", "当你暗置此武将牌时",
  "当你明置另一张武将牌后", "当你明置武将牌后",
  "首次明置此武将牌后", "首次明置此武将牌时",
  "明置另一张武将牌后", "暗置另一张武将牌后",
  "明置此武将牌后", "明置此武将牌时",
  "暗置此武将牌后", "暗置此武将牌时",
  "明置或暗置此武将牌时",
  "仅明置此武将牌", "武将牌均明置", "武将牌均暗置",
  "若你明置此武将牌", "若其明置此武将牌",
}

-- 真正会改变武将牌明暗/存亡的动作写法。逐个精确匹配，不用宽泛模式：
-- 「已明置武将牌数」「明置武将牌后」只是状态或计数引用，不该被当成动作。
local POSITION_ACTION_PHRASES = {
  "暗置此武将牌", "暗置另一张武将牌", "暗置一张武将牌",
  "暗置其一张武将牌", "暗置其武将牌", "暗置自己的一张武将牌",
  "明置此武将牌", "明置另一张武将牌", "明置一张武将牌",
  "明置其一张武将牌", "明置其武将牌", "明置自己的一张武将牌",
  -- 换将/移除/易位也动武将牌，但描述里未必出现「武将牌」三字（如【烈伐】
  -- 「变更副将」只在同一句的「明置武将牌后」里带出这三个字）。
  "变更副将", "变更主将", "变更武将牌",
  "移除副将", "移除主将", "移除武将牌",
  "主副将易位", "武将牌易位",
}

local function changesGeneralState(description)
  if type(description) ~= "string" then return false end
  local text = description
  for _, phrase in ipairs(CONDITIONAL_PHRASES) do
    text = text:gsub(phrase, "")
  end
  for _, phrase in ipairs(POSITION_ACTION_PHRASES) do
    if text:find(phrase, 1, true) then return true end
  end
  -- 换将写法中间可能插字（【选备】「变更X次副将」），用不跨小句的模式兜底。
  -- 先把中文标点换成单字节分隔符：Lua 模式按字节工作，把多字节标点直接
  -- 写进 [^...] 会被拆成字节集合，连带排除掉普通汉字。
  for _, punct in ipairs({ "，", "。", "；", "：", "、", ",", ";", ":" }) do
    text = text:gsub(punct, "|")
  end
  if text:find("变更[^|]*副将") or text:find("移除[^|]*副将") or
    text:find("变更[^|]*主将") or text:find("移除[^|]*主将") then
    return true
  end
  -- 「移除武将牌」「变更武将牌」不一定带数量词，单独按两词共现兜底。
  local changed =
    (text:find("移除", 1, true) and text:find("武将牌", 1, true)) or
    (text:find("变更", 1, true) and text:find("武将牌", 1, true))
  return changed and true or false
end

local function availableSkills(general, target, history, field_skills)
  return table.filter(general:getSkillNameList(true), function(skill_name)
    local skill = Fk.skills[skill_name]
    local description = Fk:translate(":" .. skill_name)
    -- 主将技/副将技绑定武将位置，「谶」没有所在武将牌，一律不给；
    -- 这里单独判断，不改 H.isTaggedSkill（【盈门】访客还要按位置匹配这两类标签）。
    return skill and not skill:hasTag(Skill.Lord) and
      not skill:hasTag(Skill.MainPlace) and not skill:hasTag(Skill.DeputyPlace) and
      not H.isTaggedSkill(skill) and
      not changesGeneralState(description) and
      not target:hasSkill(skill_name, true, true) and
      not table.contains(history, skill_name) and not field_skills[skill_name]
  end)
end

local function getChan(target)
  local v = target:getMark(chan_mark)
  return type(v) == "string" and v ~= "" and v or nil
end

-- 失去「谶」（到期回收或被新的「谶」替换）即摸一张牌；故梦把谶转为永久
-- 技能时不走这里，因为谶并没有失去。
local function clearChan(room, target, drawCard)
  local skill_name = getChan(target)
  room:setPlayerMark(target, chan_mark, 0)
  room:setPlayerMark(target, wait_mark, 0)
  if not skill_name then return nil end
  if Fk.skills[skill_name] then
    room:handleAddLoseSkills(target, "-" .. skill_name, nil, false)
  end
  -- 临时获得的技能会留下不带时限后缀的附加标记（例如裸衣的 @@hs__luoyi）。
  -- 技能移除不会自动清理这类标记，因此按技能名回收。
  local stale = {}
  for mark, _ in pairs(target.mark or {}) do
    if type(mark) == "string" and mark:find(skill_name, 1, true) then
      table.insertIfNeed(stale, mark)
    end
  end
  for _, mark in ipairs(stale) do
    room:setPlayerMark(target, mark, 0)
  end
  -- 失去谶属被动结算：摸牌不挂技能名，日志里不出现「虞照」；
  -- 到期回收的发动播报由下方 EventPhaseStart 的 mute = true 关闭。
  if drawCard then room:drawCards(target, 1) end
  return skill_name
end

yuzhao:addEffect(fk.HpChanged, {
  global = true,
  can_trigger = function(self, _, target, player)
    -- 严格同势力：compareKingdomWith 对未确定势力返回 false，不再为
    -- 「张裕与目标都未亮势力」开兜底。
    return target and player:hasSkill(self.name) and
      H.compareKingdomWith(player, target)
  end,
  on_cost = function(self, event, _, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#fengsui_heg__yuzhao-invoke",
    }) then
      event:setCostData(self, data)
      return true
    end
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local old_chan = getChan(target)
    local field_generals, field_skills = fieldGeneralsAndSkills(room)
    local history = target:getTableMark(history_mark)
    -- 只挑确实带有可用非标签技的武将牌，避免看完三张却无从选择。
    local candidates = room:findGenerals(function(name)
      local general = Fk.generals[name]
      return general and not field_generals[name] and not forbidden(general) and
        general.maxHp == target.maxHp and
        #availableSkills(general, target, history, field_skills) > 0
    end, 3)
    if #candidates == 0 then return end

    local skill_choices = {}
    for _, name in ipairs(candidates) do
      table.insert(skill_choices,
        availableSkills(Fk.generals[name], target, history, field_skills))
    end

    -- 这个对话框先展示三张武将牌及其技能，再由张裕决定：选一个技能即
    -- 获得/替换「谶」，点取消则什么都不做（替换时即「保留原谶」）。
    local selected = U.askToChooseGeneralSkills(player, {
      skill_name = self.name,
      generals = candidates,
      skills = skill_choices,
      cancelable = true,
      min_num = 1,
      max_num = 1,
      prompt = old_chan and "#fengsui_heg__yuzhao-replace" or
        "#fengsui_heg__yuzhao-choose",
    })
    local skill_name = selected and selected[1]
    if not skill_name or not Fk.skills[skill_name] then
      room:returnToGeneralPile(candidates)
      return
    end

    -- 「观看」不等于取走武将牌，三张全部归还将池；否则反复替换会耗尽将池。
    room:returnToGeneralPile(candidates)

    if old_chan then clearChan(room, target, true) end
    room:handleAddLoseSkills(target, skill_name)
    room:setPlayerMark(target, chan_mark, skill_name)
    room:setPlayerMark(target, wait_mark, 1)
    room:addTableMark(target, history_mark, skill_name)
  end,
})

-- 「谶」在获得它的角色自己的结束阶段失去：谁的回合结束，谁失去自己的「谶」；
-- 在别人回合获得的谶会一直留到该角色自己回合的结束阶段。is_delay_effect
-- 让这段锁定回收不再弹询问框。
yuzhao:addEffect(fk.EventPhaseStart, {
  global = true,
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, _, target, player)
    return target and target == player and target.phase == Player.Finish and
      target:getMark(wait_mark) > 0
  end,
  on_use = function(self, _, target)
    clearChan(target.room, target, true)
  end,
})

return yuzhao
