local H = require "packages.fengsui.hegemony_util"

local junwei = fk.CreateSkill{
  name = "fengsui_heg__junwei",
}

junwei:addEffect("arraysummon", {array_type = "formation"})

local function hiddenChoices(player)
  local choices = {}
  if player.general == "anjiang" then table.insert(choices, "fengsui_heg__junwei_main") end
  if player.deputyGeneral == "anjiang" then table.insert(choices, "fengsui_heg__junwei_deputy") end
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

junwei:addEffect(fk.TurnStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(junwei.name) and skillGeneralRevealed(player) and target and
      (target == player or H.inFormationRelation(target, player))
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    if H.allGeneralsRevealed(target) then table.insert(choices, "fengsui_heg__junwei_hide") end
    if #hiddenChoices(target) > 0 then table.insert(choices, "fengsui_heg__junwei_reveal") end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(target, {
      choices = choices,
      skill_name = junwei.name,
      prompt = "#fengsui_heg__junwei-choice::" .. player.id,
    })
    if choice ~= "Cancel" then event:setCostData(self, {choice = choice}); return true end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "fengsui_heg__junwei_hide" then
      local choices = {"fengsui_heg__junwei_main", "fengsui_heg__junwei_deputy"}
      local choice = room:askToChoice(target, {choices = choices, skill_name = junwei.name,
        prompt = "#fengsui_heg__junwei-hide"})
      local hide_deputy = choice == "fengsui_heg__junwei_deputy"
      target:hideGeneral(hide_deputy)
      if not target:hasSkill("heg__fushou", true) then
        room:handleAddLoseSkills(target, "heg__fushou")
        local turn = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
        if turn then turn:addCleaner(function()
          room:handleAddLoseSkills(target, "-heg__fushou")
        end) end
      end
    else
      local choices = hiddenChoices(target)
      local choice = room:askToChoice(target, { choices = choices, skill_name = junwei.name,
        prompt = "#fengsui_heg__junwei-reveal" })
      target:revealGeneral(choice == "fengsui_heg__junwei_deputy")
      room:drawCards(target, 2, junwei.name)
    end
  end,
})

return junwei
