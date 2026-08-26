local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tuanfeng = fk.CreateSkill{
  name = "fengsui_heg__tuanfeng",
}

local dying_flag = "fengsui_heg__tuanfeng_entered_dying"

tuanfeng:addEffect(fk.EnterDying, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event then
      use_event.data.extra_data = use_event.data.extra_data or {}
      use_event.data.extra_data[dying_flag] = true
    end
  end,
})

local function discardPileIds(room, card)
  return table.filter(Card:getIdList(card), function(id)
    return room:getCardArea(id) == Card.DiscardPile
  end)
end

tuanfeng:addEffect(fk.CardUseFinished, {
  global = true,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (target and player:hasSkill(tuanfeng.name) and H.compareKingdomWith(player, target) and
      H.allGeneralsRevealed(player) and data.card and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:getMark(tuanfeng.name .. "_type_" .. data.card.type .. "-round") == 0) then
      return false
    end
    if data.extra_data and data.extra_data[dying_flag] then return false end
    return #discardPileIds(player.room, data.card) > 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = tuanfeng.name,
      prompt = "#fengsui_heg__tuanfeng-invoke::" .. target.id .. ":" .. data.card:toLogString(),
    }) then
      event:setCostData(self, { cards = discardPileIds(player.room, data.card) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, tuanfeng.name .. "_type_" .. data.card.type .. "-round", 1)
    U.hideSkillGeneral(player, tuanfeng.name)
    local ids = table.filter(event:getCostData(self).cards, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #ids > 0 then
      room:obtainCard(player, ids, true, fk.ReasonPrey, target, tuanfeng.name)
    end
    if not data.extraUse then
      target:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
  end,
})

return tuanfeng
