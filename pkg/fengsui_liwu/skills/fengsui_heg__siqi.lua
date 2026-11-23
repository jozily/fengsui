local H = require "packages.fengsui.hegemony_util"

local siqi = fk.CreateSkill {
  name = "fengsui_heg__siqi",
}

local function sameKingdomCount(player)
  local n = 0
  for _, p in ipairs(player.room.alive_players) do
    if H.compareKingdomWith(player, p) then n = n + 1 end
  end
  return n
end

siqi:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(siqi.name) and
      #player.room.draw_pile > 0 and sameKingdomCount(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = siqi.name,
      prompt = "#fengsui_heg__siqi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = math.min(sameKingdomCount(player), #room.draw_pile)
    local ids = room:getNCards(x, "bottom")
    room:moveCards{
      ids = ids, toArea = Card.Processing, moveReason = fk.ReasonJustMove,
      skillName = siqi.name, moveVisible = true,
    }
    room:showCards(ids, player)
    local gain = {}
    for _, id in ipairs(ids) do
      local card = Fk:getCardById(id)
      if card and (card.type == Card.TypeBasic or card.type == Card.TypeEquip) then
        table.insert(gain, id)
      end
    end
    if #gain > 0 then
      room:obtainCard(player, gain, true, fk.ReasonPrey, player, siqi.name)
    end
    -- 其余牌置入弃牌堆
    local rest = {}
    for _, id in ipairs(ids) do
      if not table.contains(gain, id) and room:getCardArea(id) == Card.Processing then
        table.insert(rest, id)
      end
    end
    if #rest > 0 then
      room:moveCardTo(rest, Card.DiscardPile, nil, fk.ReasonJustMove, siqi.name)
    end
  end,
})

return siqi
