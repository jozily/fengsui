local liusu = fk.CreateSkill{
  name = "fengsui_heg__liusuRemake",
}
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

liusu:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__liusuRemake",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    local room = Fk:currentRoom()
    return player:usedSkillTimes(liusu.name, Player.HistoryPhase) == 0 and
      room and #room.discard_pile > 0
  end,
  card_filter = Util.TrueFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local discarded = Fk:getCardById(effect.cards[1])
    local target_num = U.getLegalTargetNum(player, discarded)
    room:throwCard(effect.cards, liusu.name, player, player)

    local id = table.find(room.discard_pile, function(card_id)
      local card = Fk:getCardById(card_id)
      return card.name ~= discarded.name and
        (card.type == Card.TypeBasic or card:isCommonTrick()) and
        U.getLegalTargetNum(player, card) == target_num
    end)
    if not id then return end

    local card = Fk:getCardById(id)
    local unknown = #table.filter(card:getAvailableTargets(player), function(p)
      return p.kingdom == "unknown"
    end)
    room:obtainCard(player, id, true, fk.ReasonPrey, player, liusu.name)
    if unknown > 0 then
      room:addPlayerMark(player, "fengsui_heg__liusuRemake_unknown-turn", unknown)
    end
  end,
})

liusu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and
      player:getMark("fengsui_heg__liusuRemake_unknown-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local x = player:getMark("fengsui_heg__liusuRemake_unknown-turn")
    local tos = player.room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = x,
      targets = player.room.alive_players,
      prompt = "#fengsui_heg__liusuRemake-fill:::" .. x,
      skill_name = liusu.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__liusuRemake_unknown-turn", 0)
    for _, p in ipairs(event:getCostData(self).tos) do
      local n = p.maxHp - p:getHandcardNum()
      if n > 0 and p:isAlive() then p:drawCards(n, liusu.name) end
    end
  end,
})

return liusu
