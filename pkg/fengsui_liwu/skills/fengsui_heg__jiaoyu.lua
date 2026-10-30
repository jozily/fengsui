local H = require "packages.fengsui.hegemony_util"

local jiaoyu = fk.CreateSkill {
  name = "fengsui_heg__jiaoyu",
  tags = { Skill.Compulsory },
}

local function lostCardsThisTurn(player)
  local n = 0
  for _, event in ipairs(player.room.logic:getEventsOfScope(GameEvent.MoveCards, 9999,
      function() return true end, Player.HistoryTurn)) do
    for _, move in ipairs(event.data or {}) do
      if move.from == player then n = n + #(move.moveInfo or {}) end
    end
  end
  return n
end

jiaoyu:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player)
    return target and target:isAlive() and player:isAlive() and
      player:hasSkill(self.name, true, true) and
      lostCardsThisTurn(player) >= lostCardsThisTurn(target)
  end,
  on_use = function(self, event, target, player)
    -- 副将暗置时也可变更；兼容层会先还原暗将再执行变更。
    H.transformGeneral(player.room, player, false, false, 1, self.name)
  end,
})

return jiaoyu
