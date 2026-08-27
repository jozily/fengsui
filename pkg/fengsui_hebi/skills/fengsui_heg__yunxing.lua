local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local yunxing = fk.CreateSkill{
  name = "fengsui_heg__yunxing",
  tags = { Skill.Compulsory, Skill.DeputyPlace },
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
})

yunxing:addEffect(fk.FinishJudge, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yunxing.name) and data.card and
      (data.card.suit == Card.Heart or data.card.suit == Card.Spade)
  end,
  on_use = function(self, event, target, player, data)
    if data.card.suit == Card.Heart then
      player:drawCards(1, yunxing.name)
    elseif not player:isNude() then
      player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = yunxing.name,
        cancelable = false,
        prompt = "#fengsui_heg__yunxing-discard",
      })
    end
  end,
})

return yunxing
