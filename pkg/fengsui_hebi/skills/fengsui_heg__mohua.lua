local H = require "packages.fengsui.hegemony_util"

local mohua = fk.CreateSkill{
  name = "fengsui_heg__mohua",
}

local function getUsedNames(room, target)
  local names = {}
  room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
    if e.data.from == target and e.data.card then
      table.insertIfNeed(names, e.data.card.trueName)
    end
  end, Player.HistoryTurn)
  return names
end

local function canUseFuhui(player, names)
  if not player:hasSkill("fengsui_heg__fuhui") or not H.allGeneralsRevealed(player) then
    return false
  end
  local cards = player:getCardIds("he")
  if #cards < 2 then return false end
  for _, name in ipairs(names) do
    local candidate = Fk:cloneCard(name)
    if candidate.type == Card.TypeBasic or candidate:isCommonTrick() then
      local length = utf8.len(Fk:translate(name))
      for i = 1, #cards - 1 do
        for j = i + 1, #cards do
          if math.abs(Fk:getCardById(cards[i]).number - Fk:getCardById(cards[j]).number) == length then
            return true
          end
        end
      end
    end
  end
  return false
end

local function hasUsableSource(player, names)
  return table.find(player:getCardIds("h"), function(id)
    return table.contains(names, Fk:getCardById(id).trueName)
  end) ~= nil or canUseFuhui(player, names)
end

mohua:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(mohua.name) or not H.compareKingdomWith(target, player) then
      return false
    end
    local names = getUsedNames(player.room, target)
    return #names > 0 and hasUsableSource(player, names)
  end,
  on_cost = function(self, event, target, player, data)
    local names = getUsedNames(player.room, target)
    if not hasUsableSource(player, names) then return false end
    local use = player.room:askToUseCard(player, {
      pattern = table.concat(names, ","),
      skill_name = mohua.name,
      prompt = "#fengsui_heg__mohua-choice::" .. target.id,
      cancelable = true,
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
