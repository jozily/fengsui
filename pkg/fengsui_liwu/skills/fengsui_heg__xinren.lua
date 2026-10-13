local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__xinren", tags = { Skill.Compulsory } }

local function damageCard(card) return card and card.is_damage_card end
local function blackDamageIds(player)
  return table.filter(player:getCardIds("h"), function(id)
    local card = Fk:getCardById(id)
    return damageCard(card) and card.color == Card.Black
  end)
end

s:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasShownSkill(s.name) and damageCard(card) and card.color == Card.Red
  end,
})

s:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:hasShownSkill(s.name) and damageCard(card)
  end,
})

s.bypass_distances = function(self, player, skill, card)
    return player:hasShownSkill(s.name) and damageCard(card) and card.color == Card.Black
end

s:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    local sourceId = tonumber(player:getMark("fengsui_heg__yanshi_source-turn"))
    return target == player and player:hasShownSkill(s.name) and player:getMark(s.name .. "_used") == 0 and
      sourceId ~= nil and sourceId ~= player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, s.name .. "_used", 1)
    local sourceId = tonumber(player:getMark("fengsui_heg__yanshi_source-turn"))
    local source = sourceId and room:getPlayerById(sourceId) or nil
    if player.hp < 1 then room:recover { who = player, num = 1 - player.hp, recoverBy = player, skillName = s.name } end
    room:showCards(player:getCardIds("h"), player, player)
    local place = H.inGeneralSkills(player, s.name)
    if place then H.removeGeneral(player, place == "d") end
    if not source or source.dead then return end
    for _, id in ipairs(blackDamageIds(player)) do
      if player.dead then break end
      if room:getCardArea(id) == Card.PlayerHand then
        local use = room:askToUseRealCard(player, {
          pattern = tostring(Exppattern { id = { id } }), expand_pile = { id },
          skill_name = s.name, cancelable = false, skip = true,
          extra_data = { exclusive_targets = { source.id }, bypass_times = true, bypass_distances = true, extraUse = true },
        })
        if use then room:useCard(use) end
      end
    end
  end,
})

return s
