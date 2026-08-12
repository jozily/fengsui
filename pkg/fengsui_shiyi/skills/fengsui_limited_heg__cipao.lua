local H = require "packages.fengsui.hegemony_util"

local cipao = fk.CreateSkill{name = "fengsui_limited_heg__cipao"}

Fk:loadTranslationTable{
  ["fengsui_limited_heg__cipao"] = "磁炮",
  [":fengsui_limited_heg__cipao"] = "出牌阶段限一次，你可以将一张武器牌当雷【杀】使用，此牌不计入次数。若该武器攻击范围不小于X，此【杀】伤害+1（X为场上势力数）。",
  ["#fengsui_limited_heg__cipao"] = "磁炮：将一张武器牌当不计次数的雷【杀】使用",
}

local function kingdomCount(room)
  local n = 0
  for _, count in pairs(H.getKingdomPlayersNum(room)) do if count > 0 then n = n + 1 end end
  return n
end

cipao:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#fengsui_limited_heg__cipao",
  pattern = "thunder__slash",
  filter_pattern = { min_num = 1, max_num = 1, pattern = ".|.|.|.|.|weapon" },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local weapon = Fk:getCardById(cards[1])
    local card = Fk:cloneCard("thunder__slash")
    card.skillName = cipao.name
    card:addSubcard(cards[1])
    card:setMark("fengsui_limited_heg__cipao_bonus", weapon.attack_range >= kingdomCount(Fk:currentRoom()) and 1 or 0)
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(cipao.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
})

cipao:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, cipao.name) and
      data.card:getMark("fengsui_limited_heg__cipao_bonus") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return cipao
