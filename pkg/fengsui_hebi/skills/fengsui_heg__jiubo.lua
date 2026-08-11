local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local jiubo = fk.CreateSkill{
  name = "fengsui_heg__jiubo",
}

local function isFirstSingleDamageTarget(room, target, current_use)
  local events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
    local use = e.data
    return use.card.is_damage_card and #use:getAllTargets() == 1 and
      table.contains(use:getAllTargets(), target)
  end, Player.HistoryTurn)
  return #events == 1 and events[1].id == current_use.id
end

jiubo:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(jiubo.name) and H.compareKingdomWith(target, player) and
      data.card.is_damage_card and #data:getAllTargets() == 1 and
      H.allGeneralsRevealed(player)) then return false end
    local has_cost = table.find(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end)
    if not has_cost then return false end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    return use_event and isFirstSingleDamageTarget(player.room, target, use_event)
  end,
  on_cost = function(self, event, target, player, data)
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end)
    cards = U.chooseCardsFromList(player.room, player, cards, 1, 1,
      "#fengsui_heg__jiubo-invoke::" .. target.id, jiubo.name, true)
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, jiubo.name, player, player)
    U.hideSkillGeneral(player, jiubo.name)
    data:cancelTarget(target)

    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    local source_uses = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      return e.data.from == data.from
    end, Player.HistoryTurn)
    if use_event and #source_uses == 1 and source_uses[1].id == use_event.id then
      data:addTarget(player)
    end
  end,
})

return jiubo
