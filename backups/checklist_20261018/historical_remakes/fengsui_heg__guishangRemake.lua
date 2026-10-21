local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local guishang = fk.CreateSkill{
  name = "fengsui_heg__guishangRemake",
}

guishang:addEffect("active", {
  prompt = "#fengsui_heg__guishangRemake",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  min_card_num = 1,
  max_card_num = 999,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and
      not table.contains(player:getTableMark("fengsui_heg__guishangRemake_targets-turn"), to_select.id)
  end,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getCardIds("h"), to_select)
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected == 1 and #selected_cards > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "fengsui_heg__guishangRemake_targets-turn", target.id)

    local shown = effect.cards
    local command = H.askToStartCommand(player, {skill_name = guishang.name})
    if not command then return end
    room:showCards(shown, player)

    local suits = {}
    for _, id in ipairs(shown) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    local discardable = table.filter(target:getCardIds("he"), function(id)
      return not table.contains(suits, Fk:getCardById(id).suit) and not target:prohibitDiscard(id)
    end)

    local choice = "fengsui_heg__guishangRemake_gain"
    if #discardable > 0 then
      choice = room:askToChoice(target, {
        choices = {"fengsui_heg__guishangRemake_gain", "fengsui_heg__guishangRemake_discard_use"},
        prompt = "#fengsui_heg__guishangRemake-choice",
        skill_name = guishang.name,
      })
    end
    if choice == "fengsui_heg__guishangRemake_gain" then
      room:moveCardTo(shown, Card.PlayerHand, target, fk.ReasonGive, guishang.name, nil, true, player)
      if player:isAlive() and target:isAlive() then
        H.Command{tos = {target}, from = player, command = command,
          skillName = guishang.name, forced = true}
      end
      return
    end

    local discarded = U.chooseCardsFromList(room, target, discardable, 1, #discardable,
      "#fengsui_heg__guishangRemake-discard", guishang.name, false)
    room:throwCard(discarded, guishang.name, target, target)
    if target:isAlive() and player:isAlive() then
      room:useVirtualCard("await_exhausted", nil, target, {target, player}, guishang.name, true)
    end
  end,
})

guishang:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(guishang.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.to and move.toArea == Card.PlayerHand and move.from ~= move.to then
        room:addPlayerMark(move.to, "fengsui_heg__guishangRemake_obtained-turn", #move.moveInfo)
      end
    end
  end,
})

guishang:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guishang.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local sorted = table.simpleClone(room.alive_players)
    table.sort(sorted, function(a, b)
      return a:getMark("fengsui_heg__guishangRemake_obtained-turn") >
        b:getMark("fengsui_heg__guishangRemake_obtained-turn")
    end)
    if #sorted < 2 then return end
    local most, least = sorted[1], sorted[#sorted]
    if most:getMark("fengsui_heg__guishangRemake_obtained-turn") ==
      sorted[2]:getMark("fengsui_heg__guishangRemake_obtained-turn") then return end
    if least:getMark("fengsui_heg__guishangRemake_obtained-turn") ==
      sorted[#sorted - 1]:getMark("fengsui_heg__guishangRemake_obtained-turn") then return end
    room:damage{from = most, to = least, damage = 1, skillName = guishang.name}
  end,
})

return guishang
