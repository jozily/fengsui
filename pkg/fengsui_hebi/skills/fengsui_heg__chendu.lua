-- 尘牍（李密）
-- 当你于回合外交给其他角色牌后，若其与你势力相同，其可以变更副将。
local H = require "packages.fengsui.hegemony_util"

local chendu = fk.CreateSkill{
  name = "fengsui_heg__chendu",
}

-- 本回合外由 player 交给其他角色的牌的收牌人（同势力、存活）
local function giveTargets(room, player, data)
  local tos = {}
  local current = room.current
  if not current or current == player then return tos end -- 仅回合外
  for _, move in ipairs(data) do
    if move.from == player and move.to and move.to ~= player and
      move.toArea == Card.PlayerHand and move.to:isAlive() and
      move.moveReason == fk.ReasonGive and H.compareKingdomWith(move.to, player) then
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand then
          table.insertIfNeed(tos, move.to)
          break
        end
      end
    end
  end
  return tos
end

chendu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.dead or not player:hasSkill(chendu.name) then return false end
    return #giveTargets(player.room, player, data) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(giveTargets(room, player, data)) do
      if to:isAlive() then
        local confirmed = room:askToSkillInvoke(to, {
          skill_name = chendu.name,
          prompt = "#fengsui_heg__chendu-invoke",
        })
        if confirmed then
          H.transformGeneral(room, to, false, false, 1, chendu.name)
        end
      end
    end
  end,
})

return chendu
