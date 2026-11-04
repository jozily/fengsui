local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local s = fk.CreateSkill { name = "fengsui_heg__jiange" }
s.bypass_distances = function(self, player, skill, card)
  return card and card.skillName == s.name
end

-- 响应请求（求杀等）时按 pattern 自动匹配，出牌阶段则由玩家自选
local function responseName()
  local pattern = Fk.currentResponsePattern
  if not pattern then return end
  local exp = Exppattern:Parse(pattern)
  if exp:match(Fk:cloneCard("slash")) then return "slash" end
  if exp:match(Fk:cloneCard("duel")) then return "duel" end
end

s:addEffect("viewas", {
  pattern = "slash,duel",
  handly_pile = true,
  interaction = function(self, player)
    if responseName() then return end
    return CardNameUI.create(s.name, { "slash", "duel" }, { "slash", "duel" })
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local c = Fk:getCardById(to_select)
    return c.type == Card.TypeTrick or c.type == Card.TypeEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local name = responseName()
    if not name and self.interaction and self.interaction.data then
      name = self.interaction.data
    end
    if not name then return end
    local c = Fk:cloneCard(name)
    c.skillName = s.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    player:drawCards(1, s.name)
  end,
})
return s
