local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local chendu = fk.CreateSkill{
  name = "fengsui_heg__chenduRemake",
  tags = { Skill.Limited },
}

local function removedGeneralHasChendu(target, player, data)
  if target ~= player or not data.origName then return false end
  local general = Fk.generals[data.origName]
  return general and table.contains(general:getSkillNameList(), chendu.name)
end

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
    table.insert(choices, "fengsui_heg__chenduRemake_self")
  end
  if #getSwapMates(room, target) > 0 then
    table.insert(choices, "fengsui_heg__chenduRemake_other")
  end
  if H.hasGeneral(target, true) and #(room.general_pile or room.generalPile or {}) > 0 then
    table.insert(choices, "fengsui_heg__chenduRemake_transform")
  end
  return choices
end

local function swapMain(room, first, second)
  if not U.swapGenerals(room, first) or not U.swapGenerals(room, second) then return end
  H.swapDeputy(room, first, second)
  U.swapGenerals(room, first)
  U.swapGenerals(room, second)
end

chendu:addEffect(H.GeneralRemoved, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:isAlive() and target and target:isAlive() and
      (player:hasSkill(chendu.name) or removedGeneralHasChendu(target, player, data)) and
      player:usedSkillTimes(chendu.name, Player.HistoryGame) == 0 and
      #getChoices(player.room, target) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = player.room:askToChoices(player, {
      choices = getChoices(player.room, target),
      min_num = 1,
      max_num = 3,
      skill_name = chendu.name,
      prompt = "#fengsui_heg__chenduRemake-invoke::" .. target.id,
      cancelable = true,
    })
    if #choices > 0 then
      event:setCostData(self, { choices = choices })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choices

    if table.contains(choices, "fengsui_heg__chenduRemake_self") and target:isAlive() and
      U.swapGenerals(room, target) then
      room:sendLog{
        type = "#ChenduSwapSelf",
        from = target.id,
        arg = chendu.name,
      }
    end

    if table.contains(choices, "fengsui_heg__chenduRemake_other") and target:isAlive() then
      local mates = getSwapMates(room, target)
      if #mates > 0 then
        local selected = room:askToChoosePlayers(target, {
          targets = mates,
          min_num = 1,
          max_num = 1,
          skill_name = chendu.name,
          prompt = "#fengsui_heg__chenduRemake-swap",
          cancelable = false,
        })
        local mate = selected[1]
        if mate then
          local positions = {}
          if H.hasGeneral(target, false) and H.hasGeneral(mate, false) then
            table.insert(positions, "fengsui_heg__chenduRemake_main")
          end
          if H.hasGeneral(target, true) and H.hasGeneral(mate, true) then
            table.insert(positions, "fengsui_heg__chenduRemake_deputy")
          end
          local position = #positions == 1 and positions[1] or room:askToChoice(target, {
            choices = positions,
            skill_name = chendu.name,
            prompt = "#fengsui_heg__chenduRemake-position::" .. mate.id,
          })
          if position == "fengsui_heg__chenduRemake_main" then
            swapMain(room, target, mate)
          elseif position == "fengsui_heg__chenduRemake_deputy" then
            H.swapDeputy(room, target, mate)
          end
        end
      end
    end

    if table.contains(choices, "fengsui_heg__chenduRemake_transform") and target:isAlive() then
      H.transformGeneral(room, target, false, false, 3)
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__chenduRemake"] = "陈笃·旧",
  [":fengsui_heg__chenduRemake"] = "限定技，当场上有角色移除武将牌后，你可以令其依次执行任意项：1.主副将易位；2.与一名同势力角色主将或副将易位；3.变更副将。",
  ["#fengsui_heg__chenduRemake-invoke"] = "陈笃·旧：选择令 %dest 依次执行的任意项",
  ["#fengsui_heg__chenduRemake-swap"] = "陈笃·旧：请选择一名同势力角色进行易位",
  ["#fengsui_heg__chenduRemake-position"] = "陈笃·旧：选择与 %dest 易位的武将牌位置",
  ["fengsui_heg__chenduRemake_self"] = "主副将易位",
  ["fengsui_heg__chenduRemake_other"] = "与同势力角色易位",
  ["fengsui_heg__chenduRemake_transform"] = "变更副将",
  ["fengsui_heg__chenduRemake_main"] = "主将",
  ["fengsui_heg__chenduRemake_deputy"] = "副将",
  ["#ChenduSwapSelf"] = "受【%arg】影响，%from 的主副将进行了易位",
}

return chendu
