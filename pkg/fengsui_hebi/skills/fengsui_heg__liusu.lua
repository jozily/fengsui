local liusu = fk.CreateSkill{
  name = "fengsui_heg__liusu",
}

local unknown_num_mark = "fengsui_heg__liusu_unknown-turn"
local visible_mark = "@fengsui_heg__liusu_unknown-turn"

local function getUnknownTargets(player, card)
  if player:prohibitUse(card) or not player:canUse(card) then return {} end
  return table.filter(card:getAvailableTargets(player), function(p)
    return p.kingdom == "unknown"
  end)
end

liusu:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__liusu",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(liusu.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  include_equip = true,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = Fk:getCardById(effect.cards[1])
    local x = #getUnknownTargets(player, card)
    room:recastCard(effect.cards, player, liusu.name)
    if x > 0 then
      room:setPlayerMark(player, unknown_num_mark, x)
      room:setPlayerMark(player, visible_mark, x)
    end
  end,
})

liusu:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark(unknown_num_mark) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local x = player:getMark(unknown_num_mark)
    local tos = player.room:askToChoosePlayers(player, {
      min_num = x,
      max_num = x,
      targets = player.room.alive_players,
      prompt = "#fengsui_heg__liusu-fill:::" .. x,
      skill_name = liusu.name,
      cancelable = true,
    })
    if #tos == x then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, unknown_num_mark, 0)
    player.room:setPlayerMark(player, visible_mark, 0)
    for _, p in ipairs(event:getCostData(self).tos) do
      if p:isAlive() then
        local n = p.maxHp - p:getHandcardNum()
        if n > 0 then p:drawCards(n, liusu.name) end
      end
    end
  end,
})

return liusu
