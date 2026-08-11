local H = require "packages.fengsui.hegemony_util"

local junwei = fk.CreateSkill{
  name = "fengsui_heg__junweiRemake",
}

junwei:addEffect("arraysummon", {array_type = "formation"})

local function hiddenChoices(player)
  local choices = {}
  if player.general == "anjiang" then table.insert(choices, "fengsui_heg__junweiRemake_main") end
  if player.deputyGeneral == "anjiang" then table.insert(choices, "fengsui_heg__junweiRemake_deputy") end
  return choices
end

local function skillGeneralRevealed(player)
  for _, is_deputy in ipairs({false, true}) do
    local general = Fk.generals[H.getActualGeneral(player, is_deputy)]
    if general and table.contains(general:getSkillNameList(true), junwei.name) then
      return is_deputy and player.deputyGeneral ~= "anjiang" or
        not is_deputy and player.general ~= "anjiang"
    end
  end
  return false
end

local function grantIgnoringPlace(room, player, is_deputy)
  local general_name = H.getActualGeneral(player, is_deputy)
  local general = Fk.generals[general_name]
  if not general then return end
  for _, skill_name in ipairs(general:getSkillNameList()) do
    if not player:hasSkill(skill_name) then
      room:handleAddLoseSkills(player, skill_name)
      room:addTableMarkIfNeed(player, "fengsui_heg__junweiRemake_acquired", skill_name)
    end
  end
  room:setPlayerMark(player, "@fengsui_heg__junweiRemake-round", 1)
end

junwei:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(junwei.name) and skillGeneralRevealed(player) and target and
      H.inFormationRelation(target, player)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    if H.allGeneralsRevealed(target) then table.insert(choices, "fengsui_heg__junweiRemake_hide") end
    if #hiddenChoices(target) > 0 then table.insert(choices, "fengsui_heg__junweiRemake_reveal") end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(target, {
      choices = choices,
      skill_name = junwei.name,
      prompt = "#fengsui_heg__junweiRemake-choice::" .. player.id,
    })
    if choice ~= "Cancel" then event:setCostData(self, {choice = choice}); return true end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "fengsui_heg__junweiRemake_hide" then
      local choices = {"fengsui_heg__junweiRemake_main", "fengsui_heg__junweiRemake_deputy"}
      local choice = room:askToChoice(target, {choices = choices, skill_name = junwei.name,
        prompt = "#fengsui_heg__junweiRemake-hide"})
      local hide_deputy = choice == "fengsui_heg__junweiRemake_deputy"
      target:hideGeneral(hide_deputy)
      grantIgnoringPlace(room, target, not hide_deputy)
    else
      local choices = hiddenChoices(target)
      if #choices == 2 then table.insert(choices, "fengsui_heg__junweiRemake_both") end
      local choice = #choices == 1 and choices[1] or room:askToChoice(target, {
        choices = choices, skill_name = junwei.name, prompt = "#fengsui_heg__junweiRemake-reveal"})
      local n = choice == "fengsui_heg__junweiRemake_both" and 2 or 1
      if choice == "fengsui_heg__junweiRemake_main" or choice == "fengsui_heg__junweiRemake_both" then
        target:revealGeneral(false)
      end
      if choice == "fengsui_heg__junweiRemake_deputy" or choice == "fengsui_heg__junweiRemake_both" then
        target:revealGeneral(true)
      end
      H.addHegMark(target, "yinyangfish", n)
    end
  end,
})

junwei:addEffect(fk.TurnStart, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return #player:getTableMark("fengsui_heg__junweiRemake_acquired") > 0 and
      player:getMark("@fengsui_heg__junweiRemake-round") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, skill_name in ipairs(player:getTableMark("fengsui_heg__junweiRemake_acquired")) do
      local place = H.inGeneralSkills(player, skill_name)
      if not place or not player:canAttachSkill(skill_name, place) then
        room:handleAddLoseSkills(player, "-" .. skill_name)
      end
    end
    room:setPlayerMark(player, "fengsui_heg__junweiRemake_acquired", 0)
  end,
})

return junwei
