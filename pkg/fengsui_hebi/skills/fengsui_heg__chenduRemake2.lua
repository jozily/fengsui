-- 陈笃 · 旧版二存档（不挂载任何武将，留作 Remake）
-- 旧效果：当场上有同势力角色变更副将后，你可以令其选择一项：1.主副将易位；
-- 2.与一名同势力角色副将易位。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local chendu = fk.CreateSkill{
  name = "fengsui_heg__chenduRemake2",
}

local function getSwapMates(room, target)
  return table.filter(room.alive_players, function(p)
    if p == target or not H.compareKingdomWith(p, target) then return false end
    return H.hasGeneral(target, true) and H.hasGeneral(p, true)
  end)
end

local function getChoices(room, target)
  local choices = {}
  if H.hasGeneral(target, false) and H.hasGeneral(target, true) then
    table.insert(choices, "fengsui_heg__chenduRemake2_self")
  end
  if #getSwapMates(room, target) > 0 then
    table.insert(choices, "fengsui_heg__chenduRemake2_other")
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
    return target and target:isAlive() and data.isMain == false and player:hasShownSkill(chendu.name) and
      H.compareKingdomWith(target, player) and #getChoices(player.room, target) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chendu.name,
      prompt = "#fengsui_heg__chenduRemake2-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = getChoices(room, target)
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or room:askToChoice(target, {
      choices = choices,
      skill_name = chendu.name,
      prompt = "#fengsui_heg__chenduRemake2-choice",
    })
    if choice == "fengsui_heg__chenduRemake2_self" then
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
      prompt = "#fengsui_heg__chenduRemake2-swap",
      cancelable = false,
    })
    local mate = selected[1]
    if not mate then return end
    H.swapDeputy(room, target, mate)
  end,
})

return chendu
