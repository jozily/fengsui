local H = require "packages.fengsui.hegemony_util"

local zunweiVs = fk.CreateSkill {
  name = "fengsui_heg__zunwei_vs",
}

zunweiVs:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "jink,nullification",
  prompt = "#fengsui_heg__zunwei-response",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {},
  },
  card_filter = function() return false end,
  view_as = function(self, player, cards)
    local pattern = Fk.currentResponsePattern
    if not pattern then return end
    local exp = Exppattern:Parse(pattern)
    local name
    if exp:match(Fk:cloneCard("jink")) then
      name = "jink"
    elseif exp:match(Fk:cloneCard("nullification")) then
      name = "nullification"
    end
    if not name then return end
    local card = Fk:cloneCard(name)
    card.skillName = zunweiVs.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    H.removeGeneral(player, true, zunweiVs.name)
    if player.dead then return end
    room:throwCard(player:getCardIds("h"), zunweiVs.name, player, player)
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then player:drawCards(n, zunweiVs.name) end
  end,
  enabled_at_play = function() return false end,
  enabled_at_response = function(self, player)
    return H.hasGeneral(player, true)
  end,
  enabled_at_nullification = function(self, player)
    return H.hasGeneral(player, true)
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__zunwei_vs"] = "尊位",
  ["#fengsui_heg__zunwei-response"] = "尊位：移除副将并视为使用【闪】或【无懈可击】响应，然后弃置所有手牌并将手牌数摸至体力上限",
}

return zunweiVs
