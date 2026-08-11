local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local fumian = fk.CreateSkill{
  name = "fengsui_heg__fumianRemake",
}

local count_mark = "fengsui_heg__fumianRemake_count-turn"
local pending_mark = "fengsui_heg__fumianRemake_pending-turn"

local function revealedKingdomGenerals(room, player)
  local n = 0
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(p, player) then n = n + H.getGeneralsRevealedNum(p) end
  end
  return n
end

fumian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fumian.name) and player.phase == Player.Play and
      not player:isNude() and revealedKingdomGenerals(player.room, player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local max_num = math.min(#player:getCardIds("he"), revealedKingdomGenerals(player.room, player))
    local cards = U.chooseCardsFromList(player.room, player, player:getCardIds("he"), 1, max_num,
      "#fengsui_heg__fumianRemake-recast:::" .. max_num, fumian.name, true)
    if #cards > 0 then event:setCostData(self, {cards = cards}); return true end
  end,
  on_use = function(self, event, target, player, data)
    local cards = event:getCostData(self).cards
    player.room:recastCard(cards, player, fumian.name)
    player.room:setPlayerMark(player, count_mark, #cards)
    player.room:setPlayerMark(player, "@fengsui_heg__fumianRemake-turn", #cards)
  end,
})

fumian:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    local n = player:getMark(count_mark)
    return target == player and n > 0 and player:getMark(pending_mark) == 0 and
      Fk:translate(data.card.trueName, "zh_CN"):len() == n
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, pending_mark, data.card.trueName)
    player.room:setPlayerMark(player, count_mark, 0)
  end,
})

fumian:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getMark(pending_mark) ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = {"fengsui_heg__fumianRemake_use", "fengsui_heg__fumianRemake_draw", "Cancel"},
      skill_name = fumian.name,
      prompt = "#fengsui_heg__fumianRemake-choice::" .. player:getMark(pending_mark) .. ":" ..
        player:getMark("@fengsui_heg__fumianRemake-turn"),
    })
    if choice ~= "Cancel" then event:setCostData(self, {choice = choice}); return true end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local name = player:getMark(pending_mark)
    local n = player:getMark("@fengsui_heg__fumianRemake-turn")
    room:setPlayerMark(player, pending_mark, 0)
    if event:getCostData(self).choice == "fengsui_heg__fumianRemake_draw" then
      player:drawCards(n, fumian.name)
    else
      room:askToUseVirtualCard(player, {name = name, skill_name = fumian.name,
        prompt = "#fengsui_heg__fumianRemake-use", cancelable = false,
        extra_data = {bypass_times = true, extraUse = true}})
    end
  end,
})

return fumian
