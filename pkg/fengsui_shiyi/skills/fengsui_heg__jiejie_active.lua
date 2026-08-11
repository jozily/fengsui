local H = require "packages.fengsui.hegemony_util"

local jiejieActive = fk.CreateSkill {
  name = "fengsui_heg__jiejie_active&",
}

Fk:loadTranslationTable{
  ["fengsui_heg__jiejie_active&"] = "诚节",
  [":fengsui_heg__jiejie_active&"] = "出牌阶段限一次，你可以将所有手牌交给一名同势力且拥有〖诚节〗的角色，然后其交给你等量的牌并展示之。若你拥有〖诚节〗，则改为直接展示所有手牌。展示牌中花色唯一最少的牌本回合无使用次数限制。",
  ["#fengsui_heg__jiejie-active"] = "诚节：将所有手牌交给辛宪英，然后其交还等量的牌并展示",
  ["#fengsui_heg__jiejie-return"] = "诚节：交给 %dest %arg 张手牌",
}

local function availableOwners(player)
  return table.filter(Fk:currentRoom().alive_players, function(p)
    return p:hasShownSkill("fengsui_heg__jiejie") and
      H.compareKingdomWith(p, player) and
      p:usedSkillTimes("fengsui_heg__jiejie", Player.HistoryPhase) == 0
  end)
end

local function uniqueLeastSuit(cards)
  local counts = {}
  for _, id in ipairs(cards) do
    local card = Fk:getCardById(id)
    if card.suit ~= Card.NoSuit then
      local suit = card:getSuitString(true)
      counts[suit] = (counts[suit] or 0) + 1
    end
  end
  local least, leastCount, tied
  for suit, count in pairs(counts) do
    if not leastCount or count < leastCount then
      least, leastCount, tied = suit, count, false
    elseif count == leastCount then
      tied = true
    end
  end
  return not tied and least or nil
end

jiejieActive:addEffect("active", {
  mute = true,
  prompt = "#fengsui_heg__jiejie-active",
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and #availableOwners(player) > 0
  end,
  target_filter = function(self, player, to_select, selected)
    local owners = availableOwners(player)
    return #owners > 1 and #selected == 0 and table.contains(owners, to_select)
  end,
  feasible = function(self, player, selected)
    return (#availableOwners(player) == 1 and #selected == 0) or #selected == 1
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local owner = #effect.tos > 0 and effect.tos[1] or availableOwners(player)[1]
    if not owner then return end
    owner:addSkillUseHistory("fengsui_heg__jiejie", 1)
    owner:broadcastSkillInvoke("fengsui_heg__jiejie")
    room:notifySkillInvoked(owner, "fengsui_heg__jiejie", "support", { player.id })

    local shown
    if owner == player then
      shown = player:getCardIds("h")
      room:showCards(shown, player)
    else
      local handed = player:getCardIds("h")
      local n = #handed
      room:moveCardTo(handed, Card.PlayerHand, owner, fk.ReasonGive,
        "fengsui_heg__jiejie", nil, false, player)
      if owner.dead or player.dead then return end
      shown = room:askToCards(owner, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = "fengsui_heg__jiejie",
        prompt = "#fengsui_heg__jiejie-return::" .. player.id .. ":" .. n,
        cancelable = false,
      })
      room:moveCardTo(shown, Card.PlayerHand, player, fk.ReasonGive,
        "fengsui_heg__jiejie", nil, false, owner)
      room:showCards(shown, player)
    end

    local suit = uniqueLeastSuit(shown)
    if suit then room:addTableMarkIfNeed(player, "fengsui_heg__jiejie_suits-turn", suit) end
  end,
})

jiejieActive:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and
      table.contains(player:getTableMark("fengsui_heg__jiejie_suits-turn"), data.card:getSuitString(true))
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

jiejieActive:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(player:getTableMark("fengsui_heg__jiejie_suits-turn"),
      card:getSuitString(true))
  end,
})

return jiejieActive
