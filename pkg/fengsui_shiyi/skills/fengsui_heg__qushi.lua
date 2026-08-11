local fengsui_heg__qushi = fk.CreateSkill{
  name = "fengsui_heg__qushi",
}

Fk:loadTranslationTable{
  ["fengsui_heg__qushi"] = "趋势",
  [":fengsui_heg__qushi"] = "出牌阶段限一次，你可以摸一张牌，然后将一张手牌扣置于一名其他角色的武将牌旁（称为“趋”）。"..
  "武将牌旁有“趋”的角色的结束阶段，其移去所有“趋”，若其于此回合内使用过与移去的“趋”类别相同的牌，"..
  "你摸X张牌（X为于本回合内成为过其使用的牌的目标的角色数且至多为5）。",

  ["#fengsui_heg__qushi-active"] = "趋势：你可以摸一张牌，然后将一张手牌作为一名角色的“趋”",
  ["#fengsui_heg__qushi-choose"] = "趋势：将一张手牌置为一名角色的“趋”",
  ["$fengsui_heg__qushi_pile"] = "趋",

  ["$fengsui_heg__qushi1"] = "将军天人之姿，可令四海归心。",
  ["$fengsui_heg__qushi2"] = "小小锦上之花，难表一腔敬意。",
}

fengsui_heg__qushi:addEffect("active", {
  anim_type = "control",
  prompt = "#fengsui_heg__qushi-active",
  can_use = function(self, player)
    return player:usedSkillTimes(fengsui_heg__qushi.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:drawCards(player, 1, fengsui_heg__qushi.name)
    if player:isKongcheng() or player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|.|hand",
      skill_name = fengsui_heg__qushi.name,
      prompt = "#fengsui_heg__qushi-choose",
      cancelable = false,
    })
    local target = to[1]
    room:addTableMarkIfNeed(target, "fengsui_heg__qushi_source", player.id)
    target:addToPile("$fengsui_heg__qushi_pile", card, false, fengsui_heg__qushi.name, player)
  end,
})
fengsui_heg__qushi:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
      #player:getPile("$fengsui_heg__qushi_pile") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.map(player:getTableMark("fengsui_heg__qushi_source"), function(pid) return room:getPlayerById(pid) end)
    room:setPlayerMark(player, "fengsui_heg__qushi_source", 0)
    local cards = player:getPile("$fengsui_heg__qushi_pile")
    local card_types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(card_types, Fk:getCardById(id).type)
    end
    room:moveCardTo(player:getPile("$fengsui_heg__qushi_pile"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, fengsui_heg__qushi.name)
    local players = {}
    local yes = false
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player then
        if table.contains(card_types, use.card.type) then
          yes = true
        end
        table.insertTableIfNeed(players, use.tos)
      end
    end, Player.HistoryTurn)
    local n = math.min(#players, 5)
    if not yes or n == 0 then return end
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(n, fengsui_heg__qushi.name)
      end
    end
  end,
})
fengsui_heg__qushi:addEffect("visibility", {
  card_visible = function(self, player, card)
    if player:getPileNameOfId(card.id) == "$fengsui_heg__qushi_pile" then
      return false
    end
  end,
})

return fengsui_heg__qushi
