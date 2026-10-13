local H = require "packages.fengsui.hegemony_util"
_G.__fengsui_heg_daoli_stolen = _G.__fengsui_heg_daoli_stolen or {}
_G.__fengsui_heg_daoli_skills = _G.__fengsui_heg_daoli_skills or {}
_G.__fengsui_heg_daoli_pending = _G.__fengsui_heg_daoli_pending or {}
_G.__fengsui_heg_daoli_marks = _G.__fengsui_heg_daoli_marks or {}
_G.__fengsui_heg_daoli_disabled = _G.__fengsui_heg_daoli_disabled or {}

local s = fk.CreateSkill { name = "fengsui_heg__daoli_extra", tags = { Skill.Compulsory } }

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
  local marks = _G.__fengsui_heg_daoli_marks[player.id]
  if marks then
    for mark, count in pairs(marks) do
      if count > 0 then H.removeHegMark(room, player, mark, count) end
    end
    _G.__fengsui_heg_daoli_marks[player.id] = nil
  end
  local skills = _G.__fengsui_heg_daoli_pending[player.id]
  if skills then
    room:handleAddLoseSkills(player, table.concat(table.map(skills, function(name) return "-" .. name end), "|"))
    _G.__fengsui_heg_daoli_pending[player.id] = nil
  end
  local disabled = _G.__fengsui_heg_daoli_disabled[player.id]
  if disabled then
    room:handleAddLoseSkills(player, table.concat(disabled, "|"), nil, false)
    _G.__fengsui_heg_daoli_disabled[player.id] = nil
  end
end

s:addEffect(fk.TurnEnd, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, _, target)
    return target and table.find(target.room.alive_players, function(p)
      return p:getMark("fengsui_heg__daoli_extra") > 0
    end) ~= nil
  end,
  on_use = function(self, _, target)
    local room = target.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("fengsui_heg__daoli_extra") > 0 then
        p:gainAnExtraPhase(Player.Play, "fengsui_heg__daoli")
      end
    end
  end,
})

s:addEffect(fk.EventPhaseStart, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, _, target)
    return target and target.phase == Player.Play and target:getMark("fengsui_heg__daoli_extra") > 0 and
      _G.__fengsui_heg_daoli_pending[target.id] ~= nil
  end,
  on_use = function(self, _, target)
    local room = target.room
    local disabled = {}
    for _, is_deputy in ipairs({false, true}) do
      local name = require("packages.fengsui.pkg.fengsui_hebi.util").getSkillPlace(target, is_deputy)
      local general = Fk.generals[require("packages.fengsui.hegemony_util").getActualGeneral(target, is_deputy)]
      if general and ((not is_deputy and target.general ~= "anjiang") or (is_deputy and target.deputyGeneral ~= "anjiang")) then
        for _, skillName in ipairs(general:getSkillNameList(true)) do
          if target:hasSkill(skillName, true, true) then
            table.insertIfNeed(disabled, "-" .. skillName)
          end
        end
      end
    end
    if #disabled > 0 then room:handleAddLoseSkills(target, table.concat(disabled, "|"), nil, false) end
    _G.__fengsui_heg_daoli_disabled[target.id] = table.map(disabled, function(name) return name:sub(2) end)
    local pending = _G.__fengsui_heg_daoli_pending[target.id]
    if pending and #pending > 0 then room:handleAddLoseSkills(target, table.concat(pending, "|"), nil, false) end
  end,
})

for _, ev in ipairs({fk.GeneralRevealed, H.GeneralTransformed}) do
  s:addEffect(ev, {
    global = true,
    is_delay_effect = true,
    can_trigger = function(self, _, target)
      return target and target:getMark("fengsui_heg__daoli_extra") > 0
    end,
    on_use = function(self, _, target)
      local room = target.room
      local disabled = _G.__fengsui_heg_daoli_disabled[target.id] or {}
      for _, is_deputy in ipairs({false, true}) do
        local general = Fk.generals[H.getActualGeneral(target, is_deputy)]
        local shown = (not is_deputy and target.general ~= "anjiang") or (is_deputy and target.deputyGeneral ~= "anjiang")
        if general and shown then
          for _, skillName in ipairs(general:getSkillNameList(true)) do
            if target:hasSkill(skillName, true, true) then
              room:handleAddLoseSkills(target, "-" .. skillName, nil, false)
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
    return target and target.phase == Player.Play and target:getMark("fengsui_heg__daoli_extra") > 0
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

return s
