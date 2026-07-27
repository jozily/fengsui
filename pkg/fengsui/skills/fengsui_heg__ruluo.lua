local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local ruluo = fk.CreateSkill{
  name = "fengsui_heg__ruluo",
}

ruluo:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and
      player:hasSkill(ruluo.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ruluo.name,
      prompt = "#fengsui_heg__ruluo-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local hand = player:getCardIds("h")
    room:showCards(hand, player)
    local basic = table.count(hand, function(id)
      return Fk:getCardById(id).type == Card.TypeBasic
    end)
    local trick = table.count(hand, function(id)
      return Fk:getCardById(id).type == Card.TypeTrick
    end)
    local diff = basic - trick

    if diff > 0 then
      room:setPlayerMark(player, "@fengsui_heg__ruluo_free-turn", diff)
      return
    end
    if diff == 0 then
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, H.getKingdom(p))
      end
      player:drawCards(#kingdoms, ruluo.name)
      return
    end

    local num = -diff
    if #player:getCardIds("he") < num then return end
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      local kingdom = H.getKingdom(p)
      if table.count(room.alive_players, function(other)
        return H.getKingdom(other) == kingdom
      end) <= num then
        table.insertIfNeed(kingdoms, kingdom)
      end
    end
    if #kingdoms == 0 then return end
    table.insert(kingdoms, "Cancel")
    local kingdom = room:askToChoice(player, {
      choices = kingdoms,
      prompt = "#fengsui_heg__ruluo-kingdom::" .. num,
      skill_name = ruluo.name,
    })
    if kingdom == "Cancel" then return end

    local cards = U.chooseCardsFromList(room, player, player:getCardIds("he"), num, num,
      "#fengsui_heg__ruluo-cards::" .. num, ruluo.name, true)
    if #cards ~= num then return end
    local trick_names = table.filter(Fk:getAllCardNames("trick"), function(name)
      return Fk:cloneCard(name):isCommonTrick()
    end)
    trick_names = player:getViewAsCardNames(ruluo.name, trick_names)
    if #trick_names == 0 then return end
    local card_name = room:askToChoice(player, {
      choices = trick_names,
      prompt = "#fengsui_heg__ruluo-trick",
      skill_name = ruluo.name,
    })
    local card = Fk:cloneCard(card_name)
    card:addSubcards(cards)
    card.skillName = ruluo.name
    room:useCard{
      from = player,
      tos = table.filter(room.alive_players, function(p)
        return H.getKingdom(p) == kingdom
      end),
      card = card,
      extraUse = true,
    }
  end,
})

ruluo:addEffect(fk.PreCardUse, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@fengsui_heg__ruluo_free-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@fengsui_heg__ruluo_free-turn")
    data.extraUse = true
  end,
})

return ruluo
