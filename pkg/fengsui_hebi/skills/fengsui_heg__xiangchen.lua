local H = require "packages.fengsui.hegemony_util"
local U = require "packages.utility.utility"

local xiangchen = fk.CreateSkill { name = "fengsui_heg__xiangchen" }

local function forbidden(general)
  return not general or general.kingdom == "wild" or
    general.kingdom == "fengsui_neutral_old" or general.kingdom == "fengsui_neutral"
end

local function currentKingdomCount(room, kingdom)
  local n = 0
  for _, p in ipairs(room.alive_players) do
    if H.getKingdom(p) == kingdom then n = n + 1 end
  end
  return n
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
    return skill and not skill:hasTag(Skill.Lord) and not position_changing and
      not target:hasSkill(skill_name, true, true) and
      not table.contains(history, skill_name) and not field_skills[skill_name]
  end)
end

local function cleanup(room, target)
  local skills = target:getTableMark("fengsui_heg__xiangchen_skills")
  local loses = table.map(skills, function(skill_name) return "-" .. skill_name end)
  if #loses > 0 then
    room:handleAddLoseSkills(target, table.concat(loses, "|"), nil, false)
  end
  -- 一些临时获得的技能会留下不带时限后缀的附加标记（例如裸衣的
  -- @@hs__luoyi）。技能移除不会自动清理这类标记，因此按技能名回收。
  local stale = {}
  for _, skill_name in ipairs(skills) do
    for mark, _ in pairs(target.mark) do
      if type(mark) == "string" and mark:find(skill_name, 1, true) then
        table.insertIfNeed(stale, mark)
      end
    end
  end
  for _, mark in ipairs(stale) do
    room:setPlayerMark(target, mark, 0)
  end
  target:setMark("fengsui_heg__xiangchen_skills", {})
  target:setMark("fengsui_heg__xiangchen_mark", 0)
  target:setMark("fengsui_heg__xiangchen_wait", 0)
  if #skills > 0 then
    room:drawCards(target, #skills, xiangchen.name)
  end
end

xiangchen:addEffect(fk.HpChanged, {
  global = true,
  can_trigger = function(self, _, target, player)
    local current = player.room.current
    local currentKingdom = current and H.getKingdom(current)
    local same_unknown = player ~= target and player.kingdom == "unknown" and
      target.kingdom == "unknown"
    return target and player:hasSkill(self.name) and
      (H.compareKingdomWith(player, target) or same_unknown) and current and
      currentKingdom ~= "fengsui_neutral_old" and
      currentKingdom ~= "fengsui_neutral"
  end,
  on_cost = function(self, event, _, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#fengsui_heg__xiangchen-invoke",
    }) then
      event:setCostData(self, data)
      return true
    end
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local current = room.current
    if not current then return end

    local currentKingdom = H.getKingdom(current)
    -- 野心家和未确定势力没有固定候选势力；此时从所有正常势力中随机取牌。
    -- 野心家的 getKingdom() 会被官方转换成 role，因此必须同时检查原始 kingdom。
    local random_kingdom = current.kingdom == "wild" or current.kingdom == "unknown" or
      currentKingdom == "unknown"
    local field_generals, field_skills = fieldGeneralsAndSkills(room)
    local history = target:getTableMark("fengsui_heg__xiangchen_history_skills")
    -- X 按相谶拥有者所属势力计算，而不是按当前回合角色所属势力计算。
    local count = math.max(1, currentKingdomCount(room, H.getKingdom(player)))
    local candidates = room:findGenerals(function(general_name)
      local general = Fk.generals[general_name]
      local kingdom_ok = random_kingdom or
        general and general.kingdom == currentKingdom
      return general and not field_generals[general_name] and not forbidden(general) and
        kingdom_ok and
        general.maxHp == current.maxHp
    end, count)
    if #candidates == 0 then return end

    local skill_choices = {}
    for _, general_name in ipairs(candidates) do
      local general = Fk.generals[general_name]
      local skills = availableSkills(general, target, history, field_skills)
      table.insert(skill_choices, skills)
    end

    if not table.find(skill_choices, function(skills) return #skills > 0 end) then
      room:returnToGeneralPile(candidates)
      return
    end

    -- 使用赵襄式“武将牌+技能”选项卡，技能与所属武将牌一一对应。
    local selected = U.askToChooseGeneralSkills(player, {
      skill_name = self.name,
      generals = candidates,
      skills = skill_choices,
      cancelable = true,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__xiangchen-choose",
    })
    local skill_name = selected and selected[1]
    local chosen_index
    if skill_name then
      for i, skills in ipairs(skill_choices) do
        if table.contains(skills, skill_name) then
          chosen_index = i
          break
        end
      end
    end
    local chosen_general = chosen_index and candidates[chosen_index]
    if not chosen_general then
      room:returnToGeneralPile(candidates)
      return
    end

    local unchosen = table.filter(candidates, function(name)
      return name ~= chosen_general
    end)
    if #unchosen > 0 then room:returnToGeneralPile(unchosen) end

    room:handleAddLoseSkills(target, skill_name)
    room:addTableMark(target, "fengsui_heg__xiangchen_skills", skill_name)
    room:addTableMark(target, "fengsui_heg__xiangchen_history_skills", skill_name)
    room:addPlayerMark(target, "fengsui_heg__xiangchen_mark", 1)
    room:setPlayerMark(target, "fengsui_heg__xiangchen_wait", 1)
  end,
})

-- 在目标下一个结束阶段清理；若目标在本回合出牌阶段获得技能，
-- 则本回合结束阶段就会失去技能。
xiangchen:addEffect(fk.EventPhaseStart, {
  global = true,
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, _, target, player)
    return target and target == player and target.phase == Player.Finish and
      target:getMark("fengsui_heg__xiangchen_wait") > 0
  end,
  on_use = function(self, _, target)
    cleanup(target.room, target)
  end,
})

return xiangchen
