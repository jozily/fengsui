local H = require "packages.fengsui.hegemony_util"
local siji = fk.CreateSkill { name = "fengsui_heg__siji" }

-- 把 +N 与 -N 合并成一个净值直接显示，避免出现“+1/-1”这种读不出结果的写法。
local function updateMark(room, target)
  local net = target:getMark(MarkEnum.AddMaxCardsInTurn) -
    target:getMark(MarkEnum.MinusMaxCardsInTurn)
  local old = target:getMark("@fengsui_heg__siji")
  if net == 0 then
    if old ~= 0 then room:setPlayerMark(target, "@fengsui_heg__siji", 0) end
    return
  end
  local text = "手牌上限" .. (net > 0 and "+" or "") .. net
  if old ~= text then room:setPlayerMark(target, "@fengsui_heg__siji", text) end
end

-- 回合标记由引擎在换回合时清空，显示标记却是自己写的字符串，
-- 因此每回合开始与结束都按引擎标记重算一遍，包含结束阶段才触发的伤害。
local function refreshAll(room)
  for _, p in ipairs(room.players) do
    if p:getMark("@fengsui_heg__siji") ~= 0 or
      p:getMark(MarkEnum.AddMaxCardsInTurn) ~= 0 or
      p:getMark(MarkEnum.MinusMaxCardsInTurn) ~= 0 then
      updateMark(room, p)
    end
  end
end

local function resolve(self, player)
  local room = player.room
  local current = room.current
  if not current then return end
  local choices = {}
  if not player:isNude() then table.insert(choices, "fengsui_heg__siji_up") end
  if current:getMaxCards() > 0 then table.insert(choices, "fengsui_heg__siji_down") end
  if #choices == 0 then return end
  local choice = room:askToChoice(player, { choices = choices, skill_name = self.name })
  if choice == "fengsui_heg__siji_up" then
    room:askToDiscard(player, { min_num = 1, max_num = 1, include_equip = true, cancelable = false, skill_name = self.name })
    room:addPlayerMark(current, MarkEnum.AddMaxCardsInTurn, 1)
  else
    room:drawCards(player, 1, self.name)
    room:addPlayerMark(current, MarkEnum.MinusMaxCardsInTurn, 1)
  end
  updateMark(room, current)
  room:broadcastProperty(current, "MaxCards")
end
siji:addEffect(fk.Damaged, {
    can_trigger = function(self, _, target, player) return target == player and player:hasShownSkill(self.name) and player.room.current end,
    on_cost = function(self, _, target, player) return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__siji-invoke" }) end,
    on_use = function(self, _, _, player) resolve(self, player) end,
  })
siji:addEffect(fk.Damage, {
    can_trigger = function(self, _, target, player, data) return player:hasShownSkill(self.name) and data and data.from == player and player.room.current ~= nil end,
    on_cost = function(self, _, target, player) return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__siji-invoke" }) end,
    on_use = function(self, _, _, player) resolve(self, player) end,
  })
siji:addEffect(fk.TurnStart, {
  global = true,
  can_refresh = function(self, _, target)
    return target ~= nil
  end,
  on_refresh = function(self, _, target)
    refreshAll(target.room)
  end,
})
siji:addEffect(fk.TurnEnd, {
  global = true,
  can_refresh = function(self, _, target)
    return target ~= nil
  end,
  on_refresh = function(self, _, target)
    refreshAll(target.room)
  end,
})
return siji
