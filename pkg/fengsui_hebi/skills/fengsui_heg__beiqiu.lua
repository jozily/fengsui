local H = require "packages.fengsui.hegemony_util"
local beiqiu = fk.CreateSkill { name = "fengsui_heg__beiqiu", tags = { Skill.Compulsory } }
local function handleShown(self, _, target, player, data)
  if not target or not player:hasShownSkill(self.name) then return false end
  return true
end
local function resolve(self, target, player)
  local room = player.room
  if H.compareKingdomWith(player, target) then
    room:drawCards(player, 1, self.name)
    room:drawCards(target, 1, self.name)
  else
    if #player:getCardIds("he") > 0 then
      room:askToDiscard(player, { min_num = 1, max_num = 1, include_equip = true, cancelable = false, skill_name = self.name })
    end
    if #target:getCardIds("he") > 0 then
      room:askToDiscard(target, { min_num = 1, max_num = 1, include_equip = true, cancelable = false, skill_name = self.name })
    end
  end
end
beiqiu:addEffect(fk.GeneralShown, {
  global = true,
  can_trigger = handleShown,
  on_use = function(self, _, target, player)
    local room = player.room
    if target ~= player and player:getMark("fengsui_heg__beiqiu_target") == 0 then
      room:setPlayerMark(player, "fengsui_heg__beiqiu_target", target.id)
      room:setPlayerMark(target, "@fengsui_heg__beiqiu_target", 1)
    end
    resolve(self, target, player)
  end,
})
beiqiu:addEffect(H.GeneralTransformed, {
  global = true,
  can_trigger = handleShown,
  on_use = function(self, _, target, player)
    local room = player.room
    if target ~= player and player:getMark("fengsui_heg__beiqiu_target") == 0 then
      room:setPlayerMark(player, "fengsui_heg__beiqiu_target", target.id)
      room:setPlayerMark(target, "@fengsui_heg__beiqiu_target", 1)
    end
    resolve(self, target, player)
  end,
})
local beiqiu_death = fk.CreateSkill { name = "fengsui_heg__beiqiu_death" }
beiqiu_death:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target and player:hasShownSkill("fengsui_heg__beiqiu") and
      player:getMark("fengsui_heg__beiqiu_target") == target.id
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__beiqiu_target", 0)
    room:setPlayerMark(target, "@fengsui_heg__beiqiu_target", 0)
    local ids = player:getCardIds("hej")
    if #ids > 0 then room:throwCard(ids, "fengsui_heg__beiqiu", player, player) end
  end,
})

beiqiu:addTest(function(room, me)
  lu.assertFalse(handleShown(nil, nil, nil, me, nil))
end)

return beiqiu

