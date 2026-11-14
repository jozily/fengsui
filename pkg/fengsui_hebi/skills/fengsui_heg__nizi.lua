local H = require "packages.fengsui.hegemony_util"
local nizi = fk.CreateSkill { name = "fengsui_heg__nizi" }
local marks = {"yinyangfish", "vanguard", "companion", "wild", "fengsui_heg_ascend", "fengsui_heg__descend"}
local KEY_PREFIX = "@!!"

local function markKey(mark) return KEY_PREFIX .. mark end
local function markOfKey(key)
  if type(key) ~= "string" or key:sub(1, #KEY_PREFIX) ~= KEY_PREFIX then return nil end
  return key:sub(#KEY_PREFIX + 1)
end
local function markLength(mark)
  local text = Fk:translate(mark, "zh_CN")
  return utf8.len(text) or #text
end
local function markCounts(player)
  local counts = {}
  for _, mark in ipairs(marks) do counts[mark] = player:getMark(markKey(mark)) or 0 end
  return counts
end
-- 剩余字数能否由手上的标记恰好凑出（允许同种标记取多枚）。
local function canFinish(counts, remaining)
  if remaining == 0 then return true end
  if remaining < 0 then return false end
  for _, mark in ipairs(marks) do
    local len = markLength(mark)
    if (counts[mark] or 0) > 0 and len <= remaining then
      counts[mark] = counts[mark] - 1
      local ok = canFinish(counts, remaining - len)
      counts[mark] = counts[mark] + 1
      if ok then return true end
    end
  end
  return false
end

nizi:addEffect(fk.CardUseFinished, { global = true,
  can_trigger = function(self, _, target, player, data)
    local card = data and data.card
    if not (target and player:hasSkill(self.name) and H.compareKingdomWith(player,target)
      and player.room.current == target
      and player:getMark(self.name .. "-processing") == 0
      and card and (card.type == Card.TypeBasic or card:isCommonTrick())) then return false end
    return canFinish(markCounts(player), card:getNameLength())
  end,
  on_use = function(self, _, _, player, data)
    local room = player.room
    local card = data.card
    local remaining = card:getNameLength()
    if not canFinish(markCounts(player), remaining) then return end

    -- 选择框：六个按钮按标记名显示，只有“选它之后仍能凑满字数”的按钮可点，
    -- 其余通过 all_choices 留在框里并置灰。点一次弃一枚，字数没凑满就再弹一次，
    -- 所以同种标记可以重复选取，“任意枚”“字数之和恰好相等”两条规则都不变。
    local all_choices = {}
    for _, mark in ipairs(marks) do table.insert(all_choices, markKey(mark)) end
    room:setPlayerMark(player, self.name .. "-processing", 1)
    local last_mark
    while remaining > 0 do
      local counts = markCounts(player)
      local choices = {}
      for _, mark in ipairs(marks) do
        local len = markLength(mark)
        if counts[mark] > 0 and len <= remaining then
          counts[mark] = counts[mark] - 1
          local ok = canFinish(counts, remaining - len)
          counts[mark] = counts[mark] + 1
          if ok then table.insert(choices, markKey(mark)) end
        end
      end
      if #choices == 0 then
        room:setPlayerMark(player, self.name .. "-processing", 0)
        return
      end
      local picked = room:askToChoice(player, {
        choices = choices, all_choices = all_choices,
        skill_name = self.name,
        prompt = ("#fengsui_heg__nizi-choice:::%d"):format(remaining),
        cancelable = false,
      })
      local mark = markOfKey(picked)
      local len = mark and markLength(mark) or 0
      if not mark or len == 0 or len > remaining or (counts[mark] or 0) < 1 then
        mark = markOfKey(choices[1])
        len = markLength(mark)
      end
      H.removeHegMark(room, player, mark, 1)
      -- 一次弃多枚时只记后选的那枚，供追迹按“最后弃置的标记”补发。
      last_mark = mark
      remaining = remaining - len
    end
    if last_mark then
      room:setPlayerMark(player, "fengsui_heg__zhuiji-last", last_mark)
    end
    local use = room:askToUseVirtualCard(player, {
      name = card.name, skill_name = self.name, cancelable = false,
    })
    room:setPlayerMark(player, self.name .. "-processing", 0)
    if not use then return end
    if H.getGeneralsRevealedNum(player) == 2 then
      local place = require("packages.fengsui.pkg.fengsui_hebi.util").getSkillPlace(player, self.name)
      if place ~= nil then player:hideGeneral(place) end
    end
  end,
})
return nizi
