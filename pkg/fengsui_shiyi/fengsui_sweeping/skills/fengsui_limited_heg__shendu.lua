local H = require "packages.hegemony.util"
local shendu = fk.CreateSkill { name = "fengsui_limited_heg__shendu", tags = { Skill.Limited, Skill.DeputyPlace } }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__shendu"] = "慎度",
  [":fengsui_limited_heg__shendu"] = "限定技，出牌阶段或当你进入濒死状态时，你可以移除主将，将手牌数与体力值调整至场上最大势力人数。",
}

local function maxKingdomCount(room)
  local counts = H.getKingdomPlayersNum(room, true)
  local n = 1
  for _, count in pairs(counts) do n = math.max(n, count) end
  return n
end

local function execute(player)
  local room = player.room
  H.removeGeneral(player, false)
  if player.dead then return end
  local n = maxKingdomCount(room)
  local hand = player:getHandcardNum()
  if hand < n then player:drawCards(n - hand, shendu.name)
  elseif hand > n then
    room:askToDiscard(player, { min_num = hand - n, max_num = hand - n,
      include_equip = false, skill_name = shendu.name, cancelable = false })
  end
  if player:isAlive() then room:changeHp(player, n - player.hp, nil, shendu.name) end
end

shendu:addEffect("active", {
  card_num = 0, target_num = 0, card_filter = Util.FalseFunc, target_filter = Util.FalseFunc,
  can_use = function(self, player) return player:usedSkillTimes(shendu.name, Player.HistoryGame) == 0 end,
  on_use = function(self, room, effect) execute(effect.from) end,
})
shendu:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shendu.name) and player:usedSkillTimes(shendu.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = shendu.name })
  end,
  on_use = function(self, event, target, player, data) execute(player) end,
})

return shendu
