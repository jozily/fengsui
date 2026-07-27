local H = require "packages.hegemony.util"

local fumian = fk.CreateSkill{
  name = "fengsui_heg__fumian",
}

fumian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fumian.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not room:askToSkillInvoke(player, {
      skill_name = fumian.name,
      prompt = "#fengsui_heg__fumian-invoke",
    }) then return false end
    local card = room:askToChooseCard(player, {
      target = player,
      flag = "h",
      prompt = "#fengsui_heg__fumian-show",
      skill_name = fumian.name,
    })
    if card then
       event:setCostData(self, { cid = card })
       return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cid = event:getCostData(self).cid
    room:showCards({cid}, player)
    room:setPlayerMark(player, "fengsui_heg__fumian_card-turn", cid)
  end,
})

fumian:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local tracked = player:getMark("fengsui_heg__fumian_card-turn")
    if tracked == 0 then return false end
    for _, move in ipairs(data) do
      if move.from == player and table.find(move.moveInfo, function(info)
        return info.cardId == tracked and info.fromArea == Card.PlayerHand
      end) then
        event:setCostData(self, {card = tracked, visible = move.moveVisible == true})
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    room:setPlayerMark(player, "fengsui_heg__fumian_card-turn", 0)
    if cost.visible then
      room:setPlayerMark(player, "fengsui_heg__fumian_use-turn", cost.card)
    else
      local same_count = table.count(room.alive_players, function(p)
        return H.compareKingdomWith(p, player)
      end)
      player:drawCards(same_count, fumian.name)
    end
  end,
})

fumian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and
      player:getMark("fengsui_heg__fumian_use-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cid = player:getMark("fengsui_heg__fumian_use-turn")
    room:setPlayerMark(player, "fengsui_heg__fumian_use-turn", 0)
    room:askToUseRealCard(player, {
      pattern = {cid},
      expand_pile = {cid},
      skill_name = fumian.name,
      prompt = "#fengsui_heg__fumian-use",
      cancelable = false,
    })
  end,
})

return fumian
