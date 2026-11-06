local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__xiawang" }

-- 请求 pattern 必须覆盖所有伤害牌牌名：引擎显示技能按钮的条件是
-- Exppattern:Parse(请求pattern):matchExp(技能pattern)，若只给手牌里那张
-- 伤害牌的牌名（例如只有 fire_attack），剑歌的 "slash,duel" 不相容，
-- 技能按钮根本不会出现，也就无法使用转化牌。
local function damagePattern()
  local names = {}
  for _, card in ipairs(Fk.cards) do
    if card.is_damage_card then table.insertIfNeed(names, card.name) end
  end
  -- 兜底：牌堆尚未生成或某些扩展伤害牌缺席时，也要保证转化技的
  -- pattern（剑歌 "slash,duel"）与请求 pattern 相容，否则技能按钮不显示。
  table.insertIfNeed(names, "slash")
  table.insertIfNeed(names, "duel")
  return table.concat(names, ",")
end

local function canUseDamage(player, from)
  for _, id in ipairs(player:getCardIds("h")) do
    local card = Fk:getCardById(id)
    if card.is_damage_card and player:canUseTo(card, from, { bypass_distances = true }) then
      return true
    end
  end
  -- 剑歌：有锦囊牌或装备牌作材料即可转化出【杀】/【决斗】
  if player:hasSkill("fengsui_heg__jiange") then
    return table.find(player:getCardIds("h"), function(id)
      local t = Fk:getCardById(id).type
      return t == Card.TypeTrick or t == Card.TypeEquip
    end) ~= nil
  end
  return false
end

s:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(s.name) and player:usedSkillTimes(s.name, Player.HistoryRound) == 0 and
      target:distanceTo(player) <= 1 and data.from and data.from ~= player and
      canUseDamage(player, data.from)
  end,
  on_cost = function(self, event, target, player, data) return player.room:askToSkillInvoke(player, {skill_name=s.name}) end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- askToUseCard 只返回 use 结构，不会自行把牌用出去，必须显式 useCard。
    local use = room:askToUseCard(player, {
      pattern = damagePattern(),
      skill_name = s.name,
      prompt = "#fengsui_heg__xiawang-invoke",
      cancelable = false,
      extra_data = { exclusive_targets = { data.from.id }, bypass_distances = true, extraUse = true },
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    end
  end,
})

return s
