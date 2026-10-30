local H = require "packages.fengsui.hegemony_util"
local beiqiu = fk.CreateSkill { name = "fengsui_heg__beiqiu", tags = { Skill.Compulsory } }
-- 亮将判定。两条效果共用，故单独抽出。
-- 必须排除阵亡者：国战规则在 fk.GameOverJudge（Death:main 里、fk.Death 之前）会
-- 调用 victim:revealGeneral 把阵亡者的武将牌公开给全场看，这条路径同样会走
-- GeneralRevealed。若不判存活，任何角色一死就白送悲秋一次摸/弃。
local function handleShown(self, _, target, player, data)
  if not target or not player then return false end
  if not target:isAlive() or not player:isAlive() then return false end
  if not player:hasSkill(self.name, true) then return false end
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
-- GeneralShown 只是引擎的亮将通知时机，技能应在随后真正的
-- GeneralRevealed 时机结算，否则其他角色亮将时可能只更新规则而不执行悲秋。
beiqiu:addEffect(fk.GeneralRevealed, {
  global = true,
  can_trigger = handleShown,
  on_use = function(self, _, target, player)
    local room = player.room
    if target ~= player and player:getMark("fengsui_heg__beiqiu_target") == 0 then
      room:setPlayerMark(player, "fengsui_heg__beiqiu_target", target.id)
      room:setPlayerMark(target, "@fengsui_heg__beiqiu_target", "所念之人")
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
      room:setPlayerMark(target, "@fengsui_heg__beiqiu_target", "所念之人")
    end
    resolve(self, target, player)
  end,
})
beiqiu:addEffect(fk.Death, {
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

