local jianhe = fk.CreateSkill {
  name = "fengsui_heg__jianhe",
  tags = { Skill.MainPlace },
}

local zhao_pile = "@[zhaoshu]"

local function responsePattern()
  return type(Fk.currentResponsePattern) == "string" and Fk.currentResponsePattern ~= "" and
    Fk.currentResponsePattern or nil
end

local function availableZhaos(player, pattern)
  return table.filter(player:getPile(zhao_pile), function(id)
    local card = Fk:getCardById(id)
    return card and card.name ~= "heg_zhaoshu" and (not pattern or card:matchPattern(pattern))
  end)
end

jianhe:addEffect("viewas", {
  pattern = ".",
  prompt = function()
    return responsePattern() and "#fengsui_heg__jianhe-response" or "#fengsui_heg__jianhe"
  end,
  expand_pile = zhao_pile,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 or player:getPileNameOfId(to_select) ~= zhao_pile then return false end
    local card = Fk:getCardById(to_select)
    local pattern = responsePattern()
    return card and card.name ~= "heg_zhaoshu" and (not pattern or card:matchPattern(pattern))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local real = Fk:getCardById(cards[1])
    local card = Fk:cloneCard(real.name, real.suit, real.number)
    card:addSubcard(cards[1])
    card.skillName = jianhe.name
    return card
  end,
  after_use = function(self, player, use)
    local card = use.card
    if player.dead or not card then return end
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id).suit ~= card.suit
    end)
    if #cards == 0 then return end
    local chosen = player.room:askToCards(player, {
      min_num = 1, max_num = 1, include_equip = true,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = jianhe.name,
      prompt = "#fengsui_heg__jianhe-put:::" .. Fk:translate(Card.getSuitString(card, true)),
      cancelable = false,
    })
    if #chosen > 0 then player:addToPile(zhao_pile, chosen, true, jianhe.name) end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(jianhe.name, Player.HistoryTurn) == 0 and #availableZhaos(player) > 0
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local pattern = responsePattern()
    return player:usedSkillTimes(jianhe.name, Player.HistoryTurn) == 0 and
      pattern and #availableZhaos(player, pattern) > 0
  end,
})

return jianhe
