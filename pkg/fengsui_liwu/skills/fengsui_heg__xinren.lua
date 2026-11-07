local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__xinren", tags = { Skill.Compulsory, Skill.Limited } }

local function damageCard(card)
  return card and (card.is_damage_card or card.trueName == "fire_attack" or card.name == "fire_attack")
end
local function damageIds(player)
  return table.filter(player:getCardIds("h"), function(id)
    local card = Fk:getCardById(id)
    return damageCard(card)
  end)
end

-- prohibit/maxcards/targetmod 这类状态技注册在房间级 status_skills 上：
-- 本局只要有人获得衅刃，引擎就会对场上每个角色都调用这些回调，
-- 而不是只对技能持有者调用。必须在回调里自己判定归属，否则会变成
-- 全场共享衅刃（其它角色也用不了红色伤害牌、伤害牌不计手牌上限、
-- 黑色伤害牌无视距离）。
local function hasXinren(player)
  return player ~= nil and player:hasSkill(s.name)
end

s:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return hasXinren(player) and damageCard(card) and card.color == Card.Red
  end,
})

s:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return hasXinren(player) and damageCard(card)
  end,
})

s:addEffect("targetmod", {
  -- 不设 global = true：全局状态技在包加载时就对整个房间生效，
  -- 与是否有人选到赵娥无关，反而会把效果漏给全场。
  bypass_distances = function(self, player, skill, card)
    return hasXinren(player) and damageCard(card) and card.color == Card.Black
  end,
})

local function canTriggerAfterDetermined(self, _, target, player)
  local targetId = tonumber(player:getMark("fengsui_heg__yanshi_target"))
  return target == player and player:hasSkill(s.name) and
    player:getMark(s.name .. "_used") == 0 and player.kingdom ~= "unknown" and
    targetId ~= nil and targetId ~= player.id
end

local function useAgainstYanshiTarget(self, _, target, player)
  local room = player.room
  -- 该效果由明置/确定势力事件直接触发，不经过 SkillEffect；手动补齐
  -- 限定技的发动记录与大招特效。
  player:addSkillUseHistory(s.name, 1)
  room:notifySkillInvoked(player, s.name)
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
    H.removeGeneral(player, place == "d", s.name)
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
