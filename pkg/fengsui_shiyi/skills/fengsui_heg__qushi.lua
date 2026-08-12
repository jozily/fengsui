local H = require "packages.fengsui.hegemony_util"

local qushi = fk.CreateSkill{
  name = "fengsui_heg__qushi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fengsui_heg__qushi"] = "趋势",
  [":fengsui_heg__qushi"] = "锁定技，当你使用一张牌时，若此牌与你本回合使用的上一张牌类别相同且你以此法摸牌数小于同势力角色已明置武将牌数，你摸一张牌；类别不同，你获得你本回合上一次弃置的牌或弃置一张牌。",
  ["#fengsui_heg__qushi-choice"] = "趋势：获得本回合最后弃置的牌，或弃置一张牌",
  ["fengsui_heg__qushi_obtain"] = "获得上一次弃置的牌",
  ["fengsui_heg__qushi_discard"] = "弃置一张牌",
  ["$fengsui_heg__qushi1"] = "将军天人之姿，可令四海归心。",
  ["$fengsui_heg__qushi2"] = "小小锦上之花，难表一腔敬意。",
}

local function revealedFriends(player)
  local n = 0
  for _, p in ipairs(player.room.alive_players) do
    if H.compareKingdomWith(player, p) then n = n + H.getGeneralsRevealedNum(p) end
  end
  return n
end

qushi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(qushi.name) then return false end
    local lastType = player:getMark("fengsui_heg__qushi_type-turn")
    return lastType ~= 0 and (lastType ~= data.card.type or
      player:getMark("fengsui_heg__qushi_draw-turn") < revealedFriends(player))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("fengsui_heg__qushi_type-turn") == data.card.type then
      room:addPlayerMark(player, "fengsui_heg__qushi_draw-turn", 1)
      player:drawCards(1, qushi.name)
      return
    end
    local id = player:getMark("fengsui_heg__qushi_last_discard-turn")
    local canObtain = type(id) == "number" and id > 0 and room:getCardArea(id) == Card.DiscardPile
    local choices = {}
    if canObtain then table.insert(choices, "fengsui_heg__qushi_obtain") end
    if not player:isNude() then table.insert(choices, "fengsui_heg__qushi_discard") end
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or room:askToChoice(player, {
      choices = choices, skill_name = qushi.name, prompt = "#fengsui_heg__qushi-choice",
    })
    if choice == "fengsui_heg__qushi_obtain" then
      room:obtainCard(player, id, true, fk.ReasonPrey, player, qushi.name)
    else
      room:askToDiscard(player, { min_num = 1, max_num = 1, include_equip = true,
        skill_name = qushi.name, cancelable = false })
    end
  end,
})

qushi:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(qushi.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__qushi_type-turn", data.card.type)
  end,
})

qushi:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(qushi.name, true) and table.find(data, function(move)
      return move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    local id
    for _, move in ipairs(data) do
      if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do id = info.cardId end
      end
    end
    if id then player.room:setPlayerMark(player, "fengsui_heg__qushi_last_discard-turn", id) end
  end,
})

return qushi
