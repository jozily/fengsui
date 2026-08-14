local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local fumiao = fk.CreateSkill{
  name = "fengsui_heg__fumiao",
}

local function getUnusedBasicNames(player)
  local names = Fk:getAllCardNames("b")
  if Fk.all_card_types["rob__jink"] then table.insertIfNeed(names, "rob__jink") end
  local used = {}
  local room = player.room or Fk:currentRoom()
  -- Skill availability is also evaluated by the client, where player.room is absent.
  if not room or not room.logic then return names end
  room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
    if e.data.card.type == Card.TypeBasic then
      used[e.data.card.trueName] = true
    end
    return false
  end, Player.HistoryTurn)
  return table.filter(names, function(name)
    return not used[Fk:cloneCard(name).trueName]
  end)
end

fumiao:addEffect("viewas", {
  anim_type = "offensive",
  pattern = ".|.|.|.|.|basic",
  prompt = "#fengsui_heg__fumiao-invoke",
  interaction = function(self, player)
    if not H.allGeneralsRevealed(player) then return end
    local all_names = getUnusedBasicNames(player)
    local names = player:getViewAsCardNames(fumiao.name, all_names)
    return CardNameUI.create(fumiao.name, names, all_names)
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards > 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = fumiao.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local hand = U.chooseCardsFromList(room, player, player:getCardIds("h"), 1, 1,
      "#fengsui_heg__fumiao-pindian", fumiao.name, false)[1]
    local bottom = room.draw_pile[#room.draw_pile]
    if not hand or not bottom then return fumiao.name end
    room:moveCardTo(hand, Card.Processing, nil, fk.ReasonJustMove, fumiao.name, nil, true, player)
    room:moveCardTo(bottom, Card.Processing, nil, fk.ReasonJustMove, fumiao.name, nil, true, player)
    room:showCards({hand, bottom}, player)

    if Fk:getCardById(hand).number > Fk:getCardById(bottom).number then
      room:moveCardTo({hand, bottom}, Card.DiscardPile, nil,
        fk.ReasonPutIntoDiscardPile, fumiao.name, nil, true, player)
      return
    end

    U.hideSkillGeneral(player, fumiao.name)
    local top = U.chooseCardsFromList(room, player, {hand, bottom}, 1, 1,
      "#fengsui_heg__fumiao-top", fumiao.name, false)[1]
    local discard = top == hand and bottom or hand
    room:moveCards({
      ids = {top},
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = fumiao.name,
      drawPilePosition = 1,
      moveVisible = true,
    })
    room:moveCardTo(discard, Card.DiscardPile, nil,
      fk.ReasonPutIntoDiscardPile, fumiao.name, nil, true, player)
    return fumiao.name
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(fumiao.name, Player.HistoryTurn) == 0 and
      H.allGeneralsRevealed(player) and not player:isKongcheng() and #getUnusedBasicNames(player) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(fumiao.name, Player.HistoryTurn) == 0 and
      H.allGeneralsRevealed(player) and not player:isKongcheng() and #getUnusedBasicNames(player) > 0
  end,
})

fumiao:addTest(function(room, me)
  local names = getUnusedBasicNames(me)
  local pattern = Exppattern:Parse(Fk.skills[fumiao.name].pattern)
  lu.assertTrue(table.contains(names, "analeptic"))
  lu.assertTrue(table.contains(names, "rob__jink"))
  lu.assertTrue(pattern:match(Fk:cloneCard("analeptic")))
  lu.assertTrue(pattern:match(Fk:cloneCard("rob__jink")))
end)

return fumiao
