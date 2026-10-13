local H = require "packages.fengsui.hegemony_util"
local nizi = fk.CreateSkill { name = "fengsui_heg__nizi" }
local marks = {"yinyangfish", "vanguard", "companion", "wild", "fengsui_heg_ascend", "fengsui_heg__descend"}
local function markLength(mark)
  local text = Fk:translate(mark, "zh_CN")
  return utf8.len(text) or #text
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
    if not (player:hasShownSkill(self.name) and target and H.compareKingdomWith(player,target)
      and player.room.current == target
      and player:getMark(self.name .. "-processing") == 0
      and card and (card.type == Card.TypeBasic or card:isCommonTrick())) then return false end
    local options = {}
    subsets(player, card:getNameLength(), 1, {}, options, 0, {})
    return #options > 0
  end,
  on_use = function(self, _, _, player, data)
    local card = data.card
    local options = {}
    subsets(player, card:getNameLength(), 1, {}, options, 0, {})
    if #options == 0 then return end
    local displayToCode = {}
    local display = table.map(options, function(code)
      local names = {}
      for mark in string.gmatch(code, "[^,]+") do
        table.insert(names, Fk:translate(mark, "zh_CN"))
      end
      local text = table.concat(names, "、")
      displayToCode[text] = code
      return text
    end)
    local picked = player.room:askToChoice(player, {
      choices = display, skill_name = self.name, prompt = "#fengsui_heg__nizi-choice",
      cancelable = false,
    })
    local selected = displayToCode[picked]
    if not selected then return end
    player.room:setPlayerMark(player, self.name .. "-processing", 1)
    for mark in string.gmatch(selected, "[^,]+") do H.removeHegMark(player.room, player, mark, 1) end
    local use = player.room:askToUseVirtualCard(player, {
      name = card.name, skill_name = self.name, cancelable = false,
    })
    player.room:setPlayerMark(player, self.name .. "-processing", 0)
    if not use then return end
    if H.getGeneralsRevealedNum(player) == 2 then
      local place = require("packages.fengsui.pkg.fengsui_hebi.util").getSkillPlace(player, self.name)
      if place ~= nil then player:hideGeneral(place) end
    end
  end,
})
return nizi
