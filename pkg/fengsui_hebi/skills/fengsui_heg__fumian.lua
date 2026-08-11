local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local fumian = fk.CreateSkill{
  name = "fengsui_heg__fumian",
}

local function isOnlyMajorKingdom(player)
  local kingdoms = U.getMajorKingdoms(player.room)
  return H.isBigKingdomPlayer(player) and #kingdoms == 1 and kingdoms[1] == H.getKingdom(player)
end

fumian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fumian.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local choices = player.room:askToChoices(player, {
      choices = {"fumian_draw", "fumian_slash", "fumian_maxcards"},
      min_num = 1,
      max_num = isOnlyMajorKingdom(player) and 2 or 1,
      skill_name = fumian.name,
      prompt = "#fengsui_heg__fumian-choice",
      cancelable = true,
    })
    if #choices > 0 then
      event:setCostData(self, {choices = choices})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choices
    room:setPlayerMark(player, "@fengsui_heg__fumian-turn", choices)
    if table.contains(choices, "fumian_draw") then room:setPlayerMark(player, "fengsui_heg__fumian_draw-turn", 1) end
    if table.contains(choices, "fumian_slash") then room:setPlayerMark(player, "fengsui_heg__fumian_slash-turn", 1) end
    if table.contains(choices, "fumian_maxcards") then room:setPlayerMark(player, "fengsui_heg__fumian_maxcards-turn", 1) end
  end,
})

fumian:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__fumian_draw-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

fumian:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:getMark("fengsui_heg__fumian_slash-turn") > 0 and
      skill.trueName == "slash_skill" and scope == Player.HistoryPhase then return 1 end
  end,
})

fumian:addEffect("maxcards", {
  correct_func = function(self, player)
    return player:getMark("fengsui_heg__fumian_maxcards-turn")
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__fumian-choice"] = "福绵：选择本回合增加的一项",
  ["fumian_draw"] = "摸牌阶段摸牌数+1",
  ["fumian_slash"] = "出牌阶段使用【杀】次数+1",
  ["fumian_maxcards"] = "手牌上限+1",
  ["@fengsui_heg__fumian-turn"] = "福绵：",
}

return fumian
