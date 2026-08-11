local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local fumian = fk.CreateSkill{
  name = "fengsui_heg__fumianRemake2",
}

local function sameKingdomNum(player)
  return #table.filter(player.room.alive_players, function(p)
    return H.compareKingdomWith(player, p)
  end)
end

fumian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fumian.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local max_num = H.isBigKingdomPlayer(player) and #U.getMajorKingdoms(player.room) == 1 and 2 or 1
    local choices = player.room:askToChoices(player, {
      choices = {"fumianRemake2_draw", "fumianRemake2_slash", "fumianRemake2_maxcards"},
      min_num = 1,
      max_num = max_num,
      skill_name = fumian.name,
      prompt = "#fengsui_heg__fumianRemake2-choice:::" .. sameKingdomNum(player),
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
    room:setPlayerMark(player, "@fengsui_heg__fumianRemake2-turn", choices)
    if table.contains(choices, "fumianRemake2_draw") then
      room:setPlayerMark(player, "fengsui_heg__fumianRemake2_draw-turn", sameKingdomNum(player))
    end
    if table.contains(choices, "fumianRemake2_slash") then
      room:setPlayerMark(player, "fengsui_heg__fumianRemake2_slash-turn", sameKingdomNum(player))
    end
    if table.contains(choices, "fumianRemake2_maxcards") then
      room:setPlayerMark(player, "fengsui_heg__fumianRemake2_maxcards-turn", sameKingdomNum(player))
    end
  end,
})

fumian:addEffect(fk.DrawNCards, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__fumianRemake2_draw-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = player:getMark("fengsui_heg__fumianRemake2_draw-turn")
  end,
})

fumian:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    local n = player:getMark("fengsui_heg__fumianRemake2_slash-turn")
    if n > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then return n - 1 end
  end,
})

fumian:addEffect("maxcards", {
  fixed_func = function(self, player)
    local n = player:getMark("fengsui_heg__fumianRemake2_maxcards-turn")
    if n > 0 then return n end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__fumianRemake2"] = "福绵·旧",
  [":fengsui_heg__fumianRemake2"] = "准备阶段开始时，你可令本回合摸牌阶段摸牌数、出牌阶段出【杀】次数、手牌上限其中任一项改为X（X为同势力角色数），若你所处势力为全场唯一大势力，你可额外选择一项。",
  ["#fengsui_heg__fumianRemake2-choice"] = "福绵：选择至多两项改为 %arg",
  ["fumianRemake2_draw"] = "摸牌阶段摸牌数",
  ["fumianRemake2_slash"] = "出牌阶段使用【杀】次数",
  ["fumianRemake2_maxcards"] = "手牌上限",
  ["@fengsui_heg__fumianRemake2-turn"] = "福绵：",
}

return fumian
