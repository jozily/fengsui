local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yunxing = fk.CreateSkill{
  name = "fengsui_heg__yunxingRemake",
  tags = {Skill.Compulsory},
}

yunxing:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yunxing.name) and target == player and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, yunxing.name)
    if not player:isKongcheng() then
      local ids = U.chooseCardsFromList(room, player, player:getCardIds("h"), 1, 1,
        "#fengsui_heg__yunxingRemake-top", yunxing.name, false)
      if #ids > 0 then
        room:moveCards({
          ids = ids,
          from = player,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = yunxing.name,
          drawPilePosition = 1,
          moveVisible = true,
        })
      end
    end
  end,
})

yunxing:addEffect(fk.FinishRetrial, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yunxing.name)
  end,
  on_use = function(self, event, target, player, data)
    local sum = 0
    for _, p in ipairs(player.room.alive_players) do
      if H.compareKingdomWith(p, player) then sum = sum + p.hp end
    end

    local suit = data.card.number >= sum and Card.Heart or Card.Spade
    local card = Fk:cloneCard(data.card.name, suit, data.card.number)
    if data.card.id then card:addSubcard(data.card.id) end
    card.skillName = yunxing.name
    data.card = card
  end,
})

return yunxing
