-- 张裕【虞照】（旧版【相谶】按原名留在 fengsui_heg__xiangchen.lua 作存档）
--
-- 当一名同势力的角色体力值变化后，你可以观看剩余武将池中与其勾玉相同的
-- 三张武将牌并令其获得其中一个非标签技直至回合结束（称为“谶”，
-- 若已有“谶”则改为替换，其失去“谶”后摸一张牌）。
--
-- 与旧版的区别：候选只按目标勾玉筛三张（不再看当前回合角色势力、不再按
-- 势力人数决定张数）；同时至多保留一个“谶”，替换时可在看完武将牌后取消。
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

local function availableSkills(general, target, history, field_skills)
  return table.filter(general:getSkillNameList(true), function(skill_name)
    local skill = Fk.skills[skill_name]
    local description = Fk:translate(":" .. skill_name)
    local position_changing = type(description) == "string" and (
      (description:find("移除", 1, true) and description:find("武将牌", 1, true)) or
      (description:find("变更", 1, true) and description:find("武将牌", 1, true)) or
      description:find("暗置此武将牌", 1, true) or
      description:find("暗置另一张武将牌", 1, true) or
      description:find("明置此武将牌", 1, true) or
      description:find("明置另一张武将牌", 1, true)
    )
    return skill and not skill:hasTag(Skill.Lord) and not H.isTaggedSkill(skill) and
      not position_changing and
      not target:hasSkill(skill_name, true, true) and
      not table.contains(history, skill_name) and not field_skills[skill_name]
  end)
end

local function getChan(target)
  local v = target:getMark(chan_mark)
  return type(v) == "string" and v ~= "" and v or nil
end

-- drawCard 为 true 表示「失去谶」自然到期，按描述摸一张牌；替换旧谶时
-- 传 false，否则反复替换可以白摸牌。故梦会把谶转为永久技能，也不走这里。
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
  -- 到期回收属被动结算：摸牌不挂技能名，日志里不出现「虞照」；
  -- 技能发动播报由下方 EventPhaseStart 的 mute = true 关闭。
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

    if old_chan then clearChan(room, target, false) end
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
