local H = require "packages.fengsui.hegemony_util"

local cipao = fk.CreateSkill{name = "fengsui_toaru__heg__cipao"}

Fk:loadTranslationTable{
  ["fengsui_toaru__heg__cipao"] = "磁炮",
  [":fengsui_toaru__heg__cipao"] = "出牌阶段限一次，你可以将一张武器牌当雷【杀】使用，此牌不计入次数。若该武器攻击范围不小于X，此【杀】伤害+1（X为场上势力数）。",
  ["#fengsui_toaru__heg__cipao"] = "磁炮：将一张武器牌当不计次数的雷【杀】使用",
}

local BONUS_MARK = "fengsui_toaru__heg__cipao_bonus"

-- view_as 在客户端预览时也会被调用，此时 Fk:currentRoom() 可能为空，
-- 直接读 room.alive_players 会报错。room 缺失时退化为 0，绝不在预览阶段崩。
local function kingdomCount(room)
  if not room then return 0 end
  local n = 0
  local ok, counts = pcall(H.getKingdomPlayersNum, room)
  if not ok or type(counts) ~= "table" then return 0 end
  for _, count in pairs(counts) do if count > 0 then n = n + 1 end end
  return n
end

cipao:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#fengsui_toaru__heg__cipao",
  pattern = "thunder__slash",
  filter_pattern = { min_num = 1, max_num = 1, pattern = ".|.|.|.|.|weapon" },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("thunder__slash")
    card.skillName = cipao.name
    card:addSubcard(cards[1])
    return card
  end,
  -- 伤害 +1 的判定放到 before_use：这里必定在服务端、能稳定拿到 room，
  -- 且 use.card 是真正结算用的那张牌，mark 会随它进入伤害事件。
  before_use = function(self, player, use)
    use.extraUse = true
    local room = player.room or (Fk.currentRoom and Fk:currentRoom())
    if not room or not use.card then return end
    local subcards = use.card.subcards
    if not subcards or #subcards == 0 then return end
    local weapon = Fk:getCardById(subcards[1])
    local attackRange = (weapon and weapon.attack_range) or 0
    use.card:setMark(BONUS_MARK, attackRange >= kingdomCount(room) and 1 or 0)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(cipao.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
})

cipao:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, cipao.name) and
      data.card:getMark(BONUS_MARK) > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return cipao
