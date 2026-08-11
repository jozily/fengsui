local H = require "packages.fengsui.hegemony_util"

local s = fk.CreateSkill { name = "fengsui_heg__xiangkui" }

local function sameKingdomCount(room, player)
  return #table.filter(room.alive_players, function(p)
    return H.compareKingdomWith(p, player)
  end)
end

local function differentTypeCards(player, cardType)
  return table.filter(player:getCardIds("h"), function(id)
    return Fk:getCardById(id):getTypeString() ~= cardType
  end)
end

s:addEffect(fk.TurnStart, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target and target ~= player and player:hasSkill(s.name) and H.compareKingdomWith(target, player) and
      not player:isKongcheng() and target:getMark(s.name .. "-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    if not player.room:askToSkillInvoke(target, { skill_name = s.name, prompt = "#fengsui_heg__xiangkui-invoke::" .. player.id }) then
      return false
    end
    local choice = player.room:askToChoice(target, {
      choices = { "basic", "trick", "equip" }, skill_name = s.name,
    })
    event:setCostData(self, choice)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, s.name .. "-turn", 1)
    local available = differentTypeCards(player, event:getCostData(self))
    if #available == 0 then return end
    local cards = room:askToCards(player, {
      min_num = 1, max_num = math.min(#available, sameKingdomCount(room, player)),
      pattern = tostring(Exppattern{ id = available }), include_equip = false,
      skill_name = s.name, prompt = "#fengsui_heg__xiangkui-give::" .. target.id,
      cancelable = true,
    })
    if #cards == 0 then return end
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, s.name, nil, true, player)
    if player:isAlive() then player:drawCards(#cards, s.name) end
  end,
})

s:addTest(function(room, me)
  lu.assertTrue(Fk:cloneCard("duel"):getTypeString() ~= "basic")
  lu.assertTrue(Fk:cloneCard("slash"):getTypeString() ~= "trick")
end)

return s
