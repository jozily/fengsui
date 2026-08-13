local skill = fk.CreateSkill {
  name = "heg_consolidate_country_skill",
}

Fk:loadTranslationTable {
  ["heg_consolidate_country"] = "固国安邦",
  [":heg_consolidate_country"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：目标角色摸八张牌，然后弃置至少六张手牌。<br />吴：你可以将以此法" ..
  "弃置的牌交给吴势力角色，每名角色至多两张。",

  ["heg_consolidate_country_skill"] = "固国安邦",
  ["#heg_consolidate_country_skill"] = "固国安邦：你摸八张牌，然后弃置至少六张手牌",
  ["#heg_consolidate_country-ask"] = "固国安邦：弃置至少六张手牌",
  ["#ggab-give"] = "固国安邦：你可以将这些牌分配给吴势力角色（每名角色至多两张）点“取消”则弃置",
}

skill:addEffect("cardskill", {
  prompt = "#heg_consolidate_country_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    local target = effect.to
    if target.dead then return end
    target:drawCards(8, skill.name)
    if not target:isKongcheng() then
      local nums = #target:getCardIds("h")
      room:askToDiscard(target, {
        min_num = 6,
        max_num = nums,
        include_equip = false,
        skill_name = skill.name,
        prompt = "#heg_consolidate_country-ask",
        cancelable = false,
      })
    end
  end,
})

--势力效果（每名吴势力角色分两张）
skill:addEffect(fk.AfterCardsMove, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    if player.kingdom ~= "wu" then return false end
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.skillName == skill.name then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.skillName == skill.name then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    local fakeMove = {
      toArea = Card.PlayerHand,
      to = player,
      moveInfo = table.map(ids, function(id) return { cardId = id, fromArea = Card.DiscardPile } end),
      moveReason = fk.ReasonJustMove,
    }
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p.kingdom == "wu" end)
    room:notifyMoveCards({ player }, { fakeMove })
    local ret = room:askToYiji(player, {
      targets = targets,
      cards = ids,
      skill_name = skill.name,
      min_num = 0,
      max_num = #ids,
      prompt = "#ggab-give",
      single_max = 2,
      skip = true,
    })     -- FIXME: expand_pile
    fakeMove = {
      from = player,
      toArea = Card.DiscardPile,
      moveInfo = table.map(ids, function(id) return { cardId = id, fromArea = Card.PlayerHand } end),
      moveReason = fk.ReasonGive,
    }
    room:notifyMoveCards({ player }, { fakeMove })
    room:doYiji(ret, player, skill.name)
  end,
})

return skill
