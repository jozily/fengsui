local H = require "packages.hegemony.util"
local s = fk.CreateSkill { name = "fengsui_heg__yanshi", tags = { Skill.Compulsory } }

local function damageCards(player)
  return table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
end

s:addEffect(fk.GeneralShown, {
  can_trigger = function(self, event, target, player, data)
    local place = H.inGeneralSkills(player, s.name)
    return target == player and player:isAlive() and player:hasShownSkill(s.name) and player:getMark(s.name .. "_target") == 0 and
      place ~= nil and data and ((place == "m" and data.m) or (place == "d" and data.d))
  end,
  on_use = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room:getOtherPlayers(player), min_num = 1, max_num = 1,
      skill_name = s.name, prompt = "#fengsui_heg__yanshi-target", cancelable = false,
    })
    if #tos > 0 then
      player.room:setPlayerMark(player, s.name .. "_target", tos[1].id)
      player.room:setPlayerMark(tos[1], "@fengsui_heg__yanshi_target", "")
    end
  end,
})

local function isMarkedPair(player, other)
  return tonumber(player:getMark(s.name .. "_target")) == other.id
end

s:addEffect(fk.DamageCaused, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and player:hasShownSkill(s.name) and data.to and isMarkedPair(player, data.to) and
      player:getMark(s.name .. "_out-round") == 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    player.room:setPlayerMark(player, s.name .. "_out-round", 1)
  end,
})

s:addEffect(fk.DamageInflicted, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:isAlive() and player:hasShownSkill(s.name) and target == player and data.from and isMarkedPair(player, data.from) and
      player:getMark(s.name .. "_in-round") == 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    player.room:setPlayerMark(player, s.name .. "_in-round", 1)
  end,
})

s:addEffect(fk.DamageInflicted, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.from ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, s.name .. "_source-turn", data.from.id)
  end,
})

s:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and player:hasShownSkill(s.name) and #damageCards(player) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:showCards(player:getCardIds("h"), player, player)
    local names = {}
    for _, id in ipairs(damageCards(player)) do table.insertIfNeed(names, Fk:getCardById(id).trueName) end
    local name = #names == 1 and names[1] or room:askToChoice(player, { choices = names, skill_name = s.name })
    local cards = table.filter(player:getCardIds("h"), function(id)
      local c = Fk:getCardById(id)
      return c.is_damage_card and c.trueName == name
    end)
    if #cards > 0 then room:throwCard(cards, s.name, player, player) end
    data.damage = 0
  end,
})

return s
