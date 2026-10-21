local H = require "packages.fengsui.hegemony_util"
local siji = fk.CreateSkill { name = "fengsui_heg__siji" }
local function updateMark(room, target)
  local plus = target:getMark(MarkEnum.AddMaxCardsInTurn)
  local minus = target:getMark(MarkEnum.MinusMaxCardsInTurn)
  local text = "手牌上限"
  if plus > 0 then text = text .. "+" .. plus end
  if minus > 0 then text = text .. (plus > 0 and "/" or "") .. "-" .. minus end
  room:setPlayerMark(target, "@fengsui_heg__siji", text)
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
siji:addEffect(fk.TurnEnd, {
  global = true,
  can_refresh = function(self, _, target)
    return target and target:getMark("@fengsui_heg__siji") ~= 0
  end,
  on_refresh = function(self, _, target)
    target.room:setPlayerMark(target, "@fengsui_heg__siji", 0)
  end,
})
return siji
