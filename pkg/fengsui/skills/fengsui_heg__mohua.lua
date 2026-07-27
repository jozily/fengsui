local H = require "packages.hegemony.util"

local mohua = fk.CreateSkill{
  name = "fengsui_heg__mohua",
}

local function getUsedNames(room, target, player)
  local names = {}
  room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
    if e.data.from == target and e.data.card then
      table.insertIfNeed(names, e.data.card.trueName)
    end
  end, Player.HistoryTurn)
  return player:getViewAsCardNames(mohua.name, names)
end

mohua:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(mohua.name) and
      H.compareKingdomWith(target, player) and #getUsedNames(player.room, target, player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseVirtualCard(player, {
      name = getUsedNames(player.room, target, player),
      skill_name = mohua.name,
      prompt = "#fengsui_heg__mohua-choice::" .. target.id,
      cancelable = true,
      skip = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
    })
    if use then
      event:setCostData(self, { use = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = event:getCostData(self).use
    use.extraUse = true
    player.room:useCard(use)
  end,
})

return mohua
