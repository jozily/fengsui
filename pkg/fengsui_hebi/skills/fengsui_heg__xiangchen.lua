local H = require "packages.fengsui.hegemony_util"
local U = require "packages.utility.utility"

local xiangchen = fk.CreateSkill { name = "fengsui_heg__xiangchen" }

local function forbidden(general)
  return not general or general.kingdom == "wild" or
    general.kingdom == "fengsui_neutral" or general.kingdom == "fengsui_neutralall"
end

local function currentKingdomCount(room, kingdom)
  local n = 0
  for _, p in ipairs(room.alive_players) do
    if H.getKingdom(p) == kingdom then n = n + 1 end
  end
  return n
end

local function availableSkills(general, target)
  return table.filter(general:getSkillNameList(true), function(skill_name)
    local skill = Fk.skills[skill_name]
    local description = Fk:translate(":" .. skill_name)
    local forbidden = type(description) == "string" and
      (description:find("移除此武将牌", 1, true) ~= nil or
        description:find("变更此武将牌", 1, true) ~= nil)
    return skill and not skill:hasTag(Skill.Lord) and
      not forbidden and
      not target:hasSkill(skill_name, true, true)
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
  target:setMark("fengsui_heg__xiangchen_ready", 0)
  if #skills > 0 then
    room:drawCards(target, #skills, xiangchen.name)
  end
end

xiangchen:addEffect(fk.HpChanged, {
  global = true,
  can_trigger = function(self, _, target, player)
    local current = player.room.current
    local currentKingdom = current and H.getKingdom(current)
    return target and player:hasShownSkill(self.name) and
      H.compareKingdomWith(player, target) and current and
      player:getMark(self.name .. "-turn") == 0 and
      current.kingdom ~= "unknown" and current.kingdom ~= "wild" and
      currentKingdom ~= "unknown" and currentKingdom ~= "wild" and
      currentKingdom ~= "fengsui_neutral" and
      currentKingdom ~= "fengsui_neutralall"
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
    local count = math.max(1, currentKingdomCount(room, currentKingdom))
    local candidates = room:findGenerals(function(general_name)
      local general = Fk.generals[general_name]
      return general and not forbidden(general) and
        general.kingdom == currentKingdom and
        general.maxHp == current.maxHp
    end, count)
    if #candidates == 0 then return end

    local skill_choices = {}
    for _, general_name in ipairs(candidates) do
      local general = Fk.generals[general_name]
      local skills = availableSkills(general, target)
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
    room:addPlayerMark(target, "fengsui_heg__xiangchen_mark", 1)
    room:setPlayerMark(player, self.name .. "-turn", 1)
    room:setPlayerMark(target, "fengsui_heg__xiangchen_wait", 1)
  end,
})

-- “其下个回合结束后”不是当前回合结束：先在其下个回合开始时挂起清除，
-- 再在该回合结束时锁定移除所有“谶”技能并摸等量牌。
xiangchen:addEffect(fk.TurnStart, {
  global = true,
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, _, target)
    return target and target:getMark("fengsui_heg__xiangchen_wait") > 0 and
      target:getMark("fengsui_heg__xiangchen_ready") == 0
  end,
  on_use = function(self, _, target)
    target.room:setPlayerMark(target, "fengsui_heg__xiangchen_ready", 1)
  end,
})

xiangchen:addEffect(fk.TurnStart, {
  global = true,
  can_refresh = function(self, _, target)
    return target ~= nil
  end,
  on_refresh = function(self, _, target)
    for _, p in ipairs(target.room.alive_players) do
      target.room:setPlayerMark(p, self.name .. "-turn", 0)
    end
  end,
})

xiangchen:addEffect(fk.TurnEnd, {
  global = true,
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, _, target)
    return target and target:getMark("fengsui_heg__xiangchen_ready") > 0
  end,
  on_use = function(self, _, target)
    cleanup(target.room, target)
  end,
})

return xiangchen
