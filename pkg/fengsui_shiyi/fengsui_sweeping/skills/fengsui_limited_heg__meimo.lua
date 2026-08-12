local U = require "packages.fengsui.pkg.fengsui_shiyi.fengsui_sweeping.sweeping_util"
local H = require "packages.hegemony.util"
local meimo = fk.CreateSkill { name = "fengsui_limited_heg__meimo" }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__meimo"] = "魅魔",
  [":fengsui_limited_heg__meimo"] = "你于回合内使用的前X张牌不计入次数，前Y张牌无距离限制。出牌阶段开始时，你可以令一名其他角色的势力在本技能计算中视为与你相同；若X=Y，你摸X张牌（X为同势力角色数，Y为场上势力数）。",
  ["#fengsui_limited_heg__meimo-choose"] = "魅魔：你可以令一名其他角色的势力在本技能计算中视为与你相同",
}

local X_MARK = "fengsui_limited_heg__meimo_x-phase"
local Y_MARK = "fengsui_limited_heg__meimo_y-phase"

meimo:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(meimo.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "fengsui_limited_heg__meimo_cards-turn")
  end,
})

meimo:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill(meimo.name) and player:getMark("fengsui_limited_heg__meimo_cards-turn") < player:getMark(X_MARK)
  end,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(meimo.name) and player:getMark("fengsui_limited_heg__meimo_cards-turn") < player:getMark(Y_MARK)
  end,
})

meimo:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(meimo.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local others = table.filter(room.alive_players, function(p) return p ~= player end)
    local chosen = #others > 0 and room:askToChoosePlayers(player, {
      targets = others,
      min_num = 1,
      max_num = 1,
      skill_name = meimo.name,
      prompt = "#fengsui_limited_heg__meimo-choose",
      cancelable = true,
    }) or {}

    local x, y = U.sameKingdomCount(player), U.kingdomCount(room)
    if #chosen > 0 and not H.compareKingdomWith(player, chosen[1]) then
      x = x + 1
      local old_kingdom = H.getKingdom(chosen[1])
      if old_kingdom and old_kingdom ~= "unknown" and old_kingdom ~= "hidden" and
        #table.filter(room.alive_players, function(p)
          return H.getKingdom(p) == old_kingdom
        end) == 1 then
        y = y - 1
      end
    end
    room:setPlayerMark(player, X_MARK, x)
    room:setPlayerMark(player, Y_MARK, y)
    if x == y then player:drawCards(x, meimo.name) end
  end,
})

return meimo
