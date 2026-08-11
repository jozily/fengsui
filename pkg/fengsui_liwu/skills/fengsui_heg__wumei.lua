local wumei = fk.CreateSkill{
  name = "fengsui_heg__wumei",
}

local function isCurio(card)
  return card and card.type == Card.TypeEquip and card.package and card.package.name == "nine_variations"
end

local function hasWumei(generalName)
  local general = Fk.generals[generalName]
  return general and table.contains(general:getSkillNameList(), wumei.name)
end

local function changedWumei(event, data)
  if event == fk.GeneralHidden then return hasWumei(data) end
  for _, name in pairs(data or {}) do
    if hasWumei(name) then return true end
  end
  return false
end

local function canTriggerWumei(self, event, target, player, data)
  return target == player and player:getMark("fengsui_heg__wumei_resolving") == 0 and
    player:hasSkill(wumei.name, true) and changedWumei(event, data)
end

local function resolveWumei(self, event, target, player, data)
  local room = player.room
  room:setPlayerMark(player, "fengsui_heg__wumei_resolving", 1)
  player:drawCards(2, wumei.name)
  if player.dead then
    room:setPlayerMark(player, "fengsui_heg__wumei_resolving", 0)
    return
  end
  local use = room:askToUseVirtualCard(player, {
    name = "tricky_heist",
    skill_name = wumei.name,
    prompt = "#fengsui_heg__wumei",
    cancelable = true,
    skip = true,
  })
  if use then
    room:setPlayerMark(player, "fengsui_heg__wumei_using", 1)
    room:setPlayerMark(player, "fengsui_heg__wumei_obtained", 0)
    room:useCard(use)
    room:setPlayerMark(player, "fengsui_heg__wumei_using", 0)
    if player:getMark("fengsui_heg__wumei_obtained") > 0 then
      room:setPlayerMark(player, "fengsui_heg__wumei_free-turn", 1)
    end
    room:setPlayerMark(player, "fengsui_heg__wumei_obtained", 0)
  end
  room:setPlayerMark(player, "fengsui_heg__wumei_resolving", 0)
end

local revealSpec = {
  anim_type = "control",
  can_trigger = canTriggerWumei,
  on_use = resolveWumei,
}

wumei:addEffect(fk.GeneralRevealed, revealSpec)
wumei:addEffect(fk.GeneralHidden, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = canTriggerWumei,
  on_use = resolveWumei,
})

wumei:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:getMark("fengsui_heg__wumei_using") == 0 then return false end
    return table.find(data, function(move)
      return move.to == player and move.toArea == Card.PlayerHand and table.find(move.moveInfo, function(info)
        return isCurio(Fk:getCardById(info.cardId))
      end)
    end) ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__wumei_obtained", 1)
  end,
})

wumei:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return player:getMark("fengsui_heg__wumei_free-turn") > 0
  end,
})

wumei:addTest(function(room, me)
  lu.assertTrue(changedWumei(fk.GeneralRevealed, { m = "fengsui_heg__zhouxuan" }))
  lu.assertTrue(changedWumei(fk.GeneralHidden, "fengsui_heg__zhouxuan"))
  lu.assertFalse(changedWumei(fk.GeneralRevealed, { d = "fengsui_heg__chenshou" }))
end)

return wumei
