local H = require "packages.fengsui.hegemony_util"
local s = fk.CreateSkill {name = "fengsui_heg__yangming"}
local function countOpenHandCards(data, player)
  local n = 0
  for _, move in ipairs(data) do
    local publicArea = table.contains({Card.Processing, Card.DiscardPile, Card.PlayerEquip, Card.PlayerJudge}, move.toArea)
    local visible = move.moveVisible == true or (move.moveVisible == nil and publicArea) or move.specialVisible == true
    if move.from == player and visible and (move.to ~= player or move.toArea ~= Card.PlayerHand) then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand then n = n + 1 end
      end
    end
  end
  return n
end
local function countThisTurn(player)
  local n = 0
  for _, e in ipairs(player.room.logic:getEventsOfScope(GameEvent.MoveCards, 9999, function() return true end, Player.HistoryTurn)) do
    n = n + countOpenHandCards(e.data, player)
    if n >= 5 then return 5 end
  end
  return n
end
s:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and player:hasSkill(s.name) and
      (H.compareKingdomWith(target, player) or player:getMark("fengsui_heg__yangming-gave-turn") > 0) and countThisTurn(player) > 0
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {skill_name = s.name})
  end,
  on_use = function(self, _, _, player) player:drawCards(countThisTurn(player), s.name) end,
})
s:addTest(function(room, me)
  lu.assertEquals(countOpenHandCards({{from = me, toArea = Card.DiscardPile, moveInfo = {{fromArea = Card.PlayerHand}, {fromArea = Card.PlayerEquip}}}}, me), 1)
  lu.assertEquals(countOpenHandCards({{from = me, to = room.players[2], toArea = Card.PlayerHand, moveVisible = false, moveInfo = {{fromArea = Card.PlayerHand}}}}, me), 0)
  lu.assertEquals(countOpenHandCards({{from = me, to = room.players[2], toArea = Card.PlayerHand, moveVisible = true, moveInfo = {{fromArea = Card.PlayerHand}}}}, me), 1)
end)
return s
