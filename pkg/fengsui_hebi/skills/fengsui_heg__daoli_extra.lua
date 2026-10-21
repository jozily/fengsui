local H = require "packages.fengsui.hegemony_util"
_G.__fengsui_heg_daoli_stolen = _G.__fengsui_heg_daoli_stolen or {}
_G.__fengsui_heg_daoli_skills = _G.__fengsui_heg_daoli_skills or {}
_G.__fengsui_heg_daoli_pending = _G.__fengsui_heg_daoli_pending or {}
_G.__fengsui_heg_daoli_marks = _G.__fengsui_heg_daoli_marks or {}
_G.__fengsui_heg_daoli_disabled = _G.__fengsui_heg_daoli_disabled or {}

local s = fk.CreateSkill { name = "#fengsui_heg__daoli_extra", tags = { Skill.Compulsory }, mute = true }

local function cleanup(room, player)
  room:setPlayerMark(player, "fengsui_heg__daoli_extra", 0)
  local stolen = _G.__fengsui_heg_daoli_stolen[player.id]
  if stolen then
    local present = table.filter(stolen, function(id)
      return table.contains(player:getCardIds("hej"), id)
    end)
    if #present > 0 then room:throwCard(present, "fengsui_heg__daoli", player, player) end
    _G.__fengsui_heg_daoli_stolen[player.id] = nil
  end
  -- 悼离获得的国战标记永久保留；这里只清理本次临时记录。
  _G.__fengsui_heg_daoli_marks[player.id] = nil
  local skills = _G.__fengsui_heg_daoli_pending[player.id]
  if skills then
    if #skills > 0 then
      room:handleAddLoseSkills(player, table.concat(table.map(skills, function(name) return "-" .. name end), "|"))
    end
    _G.__fengsui_heg_daoli_pending[player.id] = nil
  end
  local disabled = _G.__fengsui_heg_daoli_disabled[player.id]
  if disabled and #disabled > 0 then
    for _, skillName in ipairs(disabled) do
      room:validateSkill(player, skillName, "-phase", s.name)
    end
  end
  _G.__fengsui_heg_daoli_disabled[player.id] = nil
  if player:isAlive() then
    room:removeTableMark(player, MarkEnum.RevealProhibited .. "-phase", "m")
    room:removeTableMark(player, MarkEnum.RevealProhibited .. "-phase", "d")
  end
end

s:addEffect(fk.TurnEnd, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, _, target)
    return target and table.find(target.room.alive_players, function(p)
      return p:getMark("fengsui_heg__daoli_extra") == 1
    end) ~= nil
  end,
  on_use = function(self, _, target)
    local room = target.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("fengsui_heg__daoli_extra") == 1 then
        room:setPlayerMark(p, "fengsui_heg__daoli_extra", 2)
        p:gainAnExtraPhase(Player.Play, "fengsui_heg__daoli", false)
      end
    end
  end,
})

s:addEffect(fk.EventPhaseStart, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, _, target)
    return target and target.phase == Player.Play and target:getMark("fengsui_heg__daoli_extra") == 2 and
      _G.__fengsui_heg_daoli_pending[target.id] ~= nil
  end,
  on_use = function(self, _, target)
    local room = target.room
    local pending = _G.__fengsui_heg_daoli_pending[target.id]
    local pending_set = {}
    for _, name in ipairs(pending or {}) do pending_set[name] = true end
    local disabled = {}
    for _, is_deputy in ipairs({false, true}) do
      local general = Fk.generals[H.getActualGeneral(target, is_deputy)]
      local shown = (not is_deputy and target.general ~= "anjiang") or
        (is_deputy and target.deputyGeneral ~= "anjiang")
      if general and shown then
        for _, skillName in ipairs(general:getSkillNameList(true)) do
          if not pending_set[skillName] and target:hasSkill(skillName, true, true) then
            room:invalidateSkill(target, skillName, "-phase", s.name)
            table.insertIfNeed(disabled, skillName)
          end
        end
      end
    end
    room:addTableMark(target, MarkEnum.RevealProhibited .. "-phase", "m")
    room:addTableMark(target, MarkEnum.RevealProhibited .. "-phase", "d")
    _G.__fengsui_heg_daoli_disabled[target.id] = disabled
    if pending and #pending > 0 then room:handleAddLoseSkills(target, table.concat(pending, "|"), nil, false) end
  end,
})

for _, ev in ipairs({fk.GeneralRevealed, H.GeneralTransformed}) do
  s:addEffect(ev, {
    global = true,
    is_delay_effect = true,
    can_trigger = function(self, _, target)
      return target and target:getMark("fengsui_heg__daoli_extra") == 2
    end,
    on_use = function(self, _, target)
      local room = target.room
      local pending = _G.__fengsui_heg_daoli_pending[target.id] or {}
      local pending_set = {}
      for _, name in ipairs(pending) do pending_set[name] = true end
      local disabled = _G.__fengsui_heg_daoli_disabled[target.id] or {}
      for _, is_deputy in ipairs({false, true}) do
        local general = Fk.generals[H.getActualGeneral(target, is_deputy)]
        local shown = (not is_deputy and target.general ~= "anjiang") or
          (is_deputy and target.deputyGeneral ~= "anjiang")
        if general and shown then
          for _, skillName in ipairs(general:getSkillNameList(true)) do
            if not pending_set[skillName] and target:hasSkill(skillName, true, true) then
              room:invalidateSkill(target, skillName, "-phase", s.name)
              table.insertIfNeed(disabled, skillName)
            end
          end
        end
      end
      _G.__fengsui_heg_daoli_disabled[target.id] = disabled
    end,
  })
end

s:addEffect(fk.EventPhaseEnd, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, _, target)
    return target and target.phase == Player.Play and target:getMark("fengsui_heg__daoli_extra") == 2
  end,
  on_use = function(self, _, target)
    cleanup(target.room, target)
  end,
})

s:addEffect(fk.Death, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, _, target)
    return target and target:getMark("fengsui_heg__daoli_extra") > 0
  end,
  on_use = function(self, _, target)
    cleanup(target.room, target)
  end,
})

-- 旧引擎不会把骨架 mute 自动复制给每个触发器；逐个写入效果规格，
-- 避免额外阶段开始/结束瞬间产生空技能名日志。
for _, spec in ipairs(s.effect_spec_list) do
  if type(spec[3]) == "table" then spec[3].mute = true end
end

return s
