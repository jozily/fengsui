local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local chendu = fk.CreateSkill{
  name = "fengsui_heg__chendu",
}

local function getSwapMates(room, target)
  return table.filter(room.alive_players, function(p)
    if p == target or not H.compareKingdomWith(p, target) then return false end
    return (H.hasGeneral(target, false) and H.hasGeneral(p, false)) or
      (H.hasGeneral(target, true) and H.hasGeneral(p, true))
  end)
end

local function getChoices(room, target)
  local choices = {}
  if H.hasGeneral(target, false) and H.hasGeneral(target, true) then
    table.insert(choices, "fengsui_heg__chendu_self")
  end
  if #getSwapMates(room, target) > 0 then
    table.insert(choices, "fengsui_heg__chendu_other")
  end
  return choices
end

local function swapMain(room, first, second)
  if not U.swapGenerals(room, first) or not U.swapGenerals(room, second) then return end
  H.swapDeputy(room, first, second)
  U.swapGenerals(room, first)
  U.swapGenerals(room, second)
end

chendu:addEffect(H.GeneralTransformed, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target and target:isAlive() and data.isMain == false and player:hasSkill(chendu.name) and
      H.compareKingdomWith(target, player) and #getChoices(player.room, target) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chendu.name,
      prompt = "#fengsui_heg__chendu-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = getChoices(room, target)
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or room:askToChoice(target, {
      choices = choices,
      skill_name = chendu.name,
      prompt = "#fengsui_heg__chendu-choice",
    })
    if choice == "fengsui_heg__chendu_self" then
      U.swapGenerals(room, target)
      return
    end
    local mates = getSwapMates(room, target)
    if #mates == 0 then return end
    local selected = room:askToChoosePlayers(target, {
      targets = mates,
      min_num = 1,
      max_num = 1,
      skill_name = chendu.name,
      prompt = "#fengsui_heg__chendu-swap",
      cancelable = false,
    })
    local mate = selected[1]
    if not mate then return end
    local positions = {}
    if H.hasGeneral(target, false) and H.hasGeneral(mate, false) then
      table.insert(positions, "fengsui_heg__chendu_main")
    end
    if H.hasGeneral(target, true) and H.hasGeneral(mate, true) then
      table.insert(positions, "fengsui_heg__chendu_deputy")
    end
    local position = #positions == 1 and positions[1] or room:askToChoice(target, {
      choices = positions,
      skill_name = chendu.name,
      prompt = "#fengsui_heg__chendu-position::" .. mate.id,
    })
    if position == "fengsui_heg__chendu_main" then
      swapMain(room, target, mate)
    elseif position == "fengsui_heg__chendu_deputy" then
      H.swapDeputy(room, target, mate)
    end
  end,
})

return chendu
