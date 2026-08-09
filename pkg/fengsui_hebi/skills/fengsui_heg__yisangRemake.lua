local H = require "packages.fengsui.hegemony_util"

local yisang = fk.CreateSkill{
  name = "fengsui_heg__yisangRemake",
}

yisang:addEffect(fk.CardUsing, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room.current == player and data.card ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__yisangRemake_previous_color =
      player:getMark("fengsui_heg__yisangRemake_last_color-turn")
    player.room:setPlayerMark(player, "fengsui_heg__yisangRemake_last_color-turn", data.card.color)
  end,
})

yisang:addEffect(fk.TargetSpecified, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local recipient = data.to
    if not (player:hasSkill(yisang.name) and recipient and
      H.compareKingdomWith(recipient, player)) then return false end
    local previous_color = (data.extra_data or {}).fengsui_heg__yisangRemake_previous_color
    return previous_color and previous_color ~= 0 and previous_color == data.card.color
  end,
  on_cost = function(self, event, target, player, data)
    local recipient = data.to
    if player.room:askToSkillInvoke(player, {
      skill_name = yisang.name,
      prompt = "#fengsui_heg__yisangRemake-invoke::" .. recipient.id,
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

    local choices = {"fengsui_heg__yisangRemake_get"}
    if not recipient:isNude() then
      table.insert(choices, "fengsui_heg__yisangRemake_replace")
    end
    local choice = room:askToChoice(recipient, {
      choices = choices,
      skill_name = yisang.name,
      prompt = "#fengsui_heg__yisangRemake-choice",
    })
    if choice == "fengsui_heg__yisangRemake_replace" then
      local replacement = room:askToChooseCard(recipient, {
        target = recipient,
        flag = "he",
        prompt = "#fengsui_heg__yisangRemake-replace",
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
