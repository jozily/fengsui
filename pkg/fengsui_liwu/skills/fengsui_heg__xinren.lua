local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__xinren", tags = { Skill.Compulsory } }

local function damageCard(card)
  return card and (card.is_damage_card or card.trueName == "fire_attack" or card.name == "fire_attack")
end
local function damageIds(player)
  return table.filter(player:getCardIds("h"), function(id)
    local card = Fk:getCardById(id)
    return damageCard(card)
  end)
end

s:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasShownSkill(s.name) and damageCard(card) and card.color == Card.Red
  end,
})

s:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasShownSkill(s.name) and damageCard(card)
  end,
})

s:addEffect("targetmod", {
  global = true,
  bypass_distances = function(self, player, skill, card)
    return player:hasShownSkill(s.name) and damageCard(card) and card.color == Card.Black
  end,
})

local function canTriggerAfterDetermined(self, _, target, player)
  local targetId = tonumber(player:getMark("fengsui_heg__yanshi_target"))
  return target == player and player:hasShownSkill(s.name) and
    player:getMark(s.name .. "_used") == 0 and player.kingdom ~= "unknown" and
    targetId ~= nil and targetId ~= player.id
end

local function useAgainstYanshiTarget(self, _, target, player)
  local room = player.room
  room:setPlayerMark(player, s.name .. "_used", 1)
  local targetId = tonumber(player:getMark("fengsui_heg__yanshi_target"))
  local victim = targetId and room:getPlayerById(targetId) or nil
  room:showCards(player:getCardIds("h"), player, player)
  if victim and victim:isAlive() then
    for _, id in ipairs(damageIds(player)) do
      if player:isAlive() and room:getCardArea(id) == Card.PlayerHand then
        local card = Fk:getCardById(id)
        -- 这是衅刃的强制结算，不能再被“红色伤害牌不可使用”这一
        -- 常规限制拦截；火攻也在这里按伤害牌处理。
        room:useCard{
          from = player, tos = { victim }, card = card,
          extraUse = true, bypass_times = true, bypass_distances = true,
        }
      end
    end
  end
  local place = H.inGeneralSkills(player, s.name)
  if place then
    room:setPlayerMark(player, "fengsui_heg__yanshi_target", 0)
    if victim then room:setPlayerMark(victim, "@fengsui_heg__yanshi_target", 0) end
    H.removeGeneral(player, place == "d")
  end
end

s:addEffect(fk.GeneralRevealed, {
  can_trigger = canTriggerAfterDetermined,
  on_use = useAgainstYanshiTarget,
})

s:addEffect(H.GeneralTransformed, {
  can_trigger = canTriggerAfterDetermined,
  on_use = useAgainstYanshiTarget,
})

return s
