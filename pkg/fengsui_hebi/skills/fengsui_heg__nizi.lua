local H = require "packages.fengsui.hegemony_util"
local nizi = fk.CreateSkill { name = "fengsui_heg__nizi" }
local marks = {"yinyangfish", "vanguard", "companion", "wild", "fengsui_heg_ascend", "fengsui_heg__descend"}
local function markLength(mark)
  return Fk:translate(mark, "zh_CN"):len()
end
local function subsets(player, length, i, chosen, result, total, used)
  if total == length then table.insert(result, table.concat(chosen, ",")); return end
  if total > length then return end
  for j = i, #marks do
    local mark = marks[j]
    used[mark] = used[mark] or 0
    if used[mark] < player:getMark("@!!" .. mark) then
      local next_total = total + markLength(mark)
      if next_total <= length then
        table.insert(chosen, mark)
        used[mark] = used[mark] + 1
        subsets(player, length, j, chosen, result, next_total, used)
        used[mark] = used[mark] - 1
        table.remove(chosen)
      end
    end
  end
end
nizi:addEffect(fk.CardUseFinished, { global = true,
  can_trigger = function(self, _, target, player, data)
    local card = data and data.card
    return player:hasSkill(self.name) and target ~= player and H.compareKingdomWith(player,target)
      and player.room.current == target and card and (card.type == Card.TypeBasic or card:isCommonTrick())
  end,
  on_use = function(self, _, _, player, data)
    local card = data.card
    local options = {}
    subsets(player, card:getNameLength(), 1, {}, options, 0, {})
    if #options == 0 then return end
    local selected = #options == 1 and options[1] or player.room:askToChoice(player, { choices = options, skill_name = self.name })
    for mark in string.gmatch(selected, "[^,]+") do H.removeHegMark(player.room, player, mark, 1) end
    player.room:askToUseVirtualCard(player, { name = card.name, skill_name = self.name, cancelable = true })
  end,
})
return nizi
