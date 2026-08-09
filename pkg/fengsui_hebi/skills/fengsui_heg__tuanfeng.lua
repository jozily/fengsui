local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local tuanfeng = fk.CreateSkill{
  name = "fengsui_heg__tuanfeng",
}

tuanfeng:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuanfeng.name) and player.phase == Player.Play and
      not player:isNude() and #player.room.alive_players > 1
  end,
  on_cost = function(self, event, target, player, data)
    local max_num = math.min(#player:getCardIds("he"), #player.room.alive_players)
    local cards = U.chooseCardsFromList(player.room, player, player:getCardIds("he"), 1, max_num,
      "#fengsui_heg__tuanfeng-recast", tuanfeng.name, true)
    if #cards == 0 then return false end
    local targets = player.room:askToChoosePlayers(player, {
      targets = player.room.alive_players, min_num = #cards, max_num = #cards,
      skill_name = tuanfeng.name, prompt = "#fengsui_heg__tuanfeng-targets:::" .. #cards,
      cancelable = true,
    })
    if #targets == #cards then event:setCostData(self, { cards = cards, tos = targets }); return true end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    room:recastCard(cost.cards, player, tuanfeng.name)
    local original = {}
    for _, p in ipairs(cost.tos) do
      original[p.id] = p.kingdom
      room:setPlayerProperty(p, "kingdom", H.getKingdom(player))
    end

    local draw = {}
    for _, p in ipairs(room.alive_players) do
      if H.inFormationRelation(p, p) then table.insertIfNeed(draw, p) end
    end
    room:sortByAction(draw)
    for _, p in ipairs(draw) do
      if p:isAlive() then p:drawCards(1, tuanfeng.name) end
    end
    for _, p in ipairs(cost.tos) do
      room:setPlayerProperty(p, "kingdom", original[p.id])
    end
  end,
})

return tuanfeng
