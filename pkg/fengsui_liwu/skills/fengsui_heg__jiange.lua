local s = fk.CreateSkill { name = "fengsui_heg__jiange" }
s:addEffect("viewas", {
  pattern = "slash,duel",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 or player:getMark(s.name .. "-turn") ~= 0 then return false end
    local c = Fk:getCardById(to_select)
    return c.type == Card.TypeTrick or c.type == Card.TypeEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local source = Fk:getCardById(cards[1])
    local c = Fk:cloneCard(source.type == Card.TypeTrick and "slash" or "duel")
    c.skillName = s.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, s.name .. "-turn", 1)
    player:drawCards(1, s.name)
  end,
})
return s
