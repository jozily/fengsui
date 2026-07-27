local H = require "packages.hegemony.util"

local yisang = fk.CreateSkill{
  name = "fengsui_heg__yisang",
}

yisang:addEffect(fk.TargetSpecified, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local recipient = data.to
    if not (player:hasSkill(yisang.name) and recipient and
      H.compareKingdomWith(recipient, player)) then return false end
    local current = player.room.current
    if not current then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
      return e.data.from == current
    end, Player.HistoryTurn)
    local previous = events[2] and events[2].data.card
    return previous and previous:compareColorWith(data.card)
  end,
  on_cost = function(self, event, target, player, data)
    local recipient = data.to
    if player.room:askToSkillInvoke(player, {
      skill_name = yisang.name,
      prompt = "#fengsui_heg__yisang-invoke::" .. recipient.id,
    }) then
      event:setCostData(self, { to = recipient })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local recipient = event:getCostData(self).to
    local top = room:getNCards(1)[1]
    if not top then return end
    room:moveCardTo(top, Card.Processing, nil, fk.ReasonJustMove, yisang.name, nil, true, player)

    local choices = {"fengsui_heg__yisang_get"}
    if not recipient:isNude() then
      table.insert(choices, "fengsui_heg__yisang_replace")
    end
    local choice = room:askToChoice(recipient, {
      choices = choices,
      skill_name = yisang.name,
      prompt = "#fengsui_heg__yisang-choice",
    })
    if choice == "fengsui_heg__yisang_replace" then
      local replacement = room:askToChooseCard(recipient, {
        target = recipient,
        flag = "he",
        prompt = "#fengsui_heg__yisang-replace",
        skill_name = yisang.name,
      })
      room:moveCards({
        ids = {replacement},
        from = recipient,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = yisang.name,
        drawPilePosition = 1,
        moveVisible = false,
      })
    end
    if room:getCardArea(top) == Card.Processing and recipient:isAlive() then
      room:obtainCard(recipient, top, true, fk.ReasonPrey, recipient, yisang.name)
    end
  end,
})

return yisang
