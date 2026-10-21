local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yunxing = fk.CreateSkill{
  name = "fengsui_heg__yunxing",
  tags = { Skill.Compulsory, Skill.DeputyPlace },
}

local turnEffect = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yunxing.name) and target == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, yunxing.name)
    if player:isAlive() and not player:isNude() then
      local ids = U.chooseCardsFromList(room, player, player:getCardIds("he"), 1, 1,
        "#fengsui_heg__yunxing-top", yunxing.name, false)
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
}
yunxing:addEffect(fk.TurnStart, turnEffect)
yunxing:addEffect(fk.TurnEnd, turnEffect)

-- 梅花判定牌在生效前视为红桃，随后仍按正常判定流程结算。
yunxing:addEffect(fk.FinishRetrial, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(yunxing.name) and data and data.card and
      data.card.suit == Card.Club
  end,
  on_use = function(self, _, target, player, data)
    local card = data.card
    data.card = Fk:cloneCard(card.name, Card.Heart, card.number, yunxing.name, card:getEffectiveId())
  end,
})

return yunxing
