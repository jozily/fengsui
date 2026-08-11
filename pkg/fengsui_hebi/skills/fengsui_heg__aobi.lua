local aobi = fk.CreateSkill{
  name = "fengsui_heg__aobi",
  tags = { Skill.Compulsory },
}

local state_mark = "fengsui_heg__aobi_state-turn"
local damage_mark = "fengsui_heg__aobi_damage-turn"

aobi:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aobi.name)
  end,
  on_use = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "fengsui_heg__aobi_self", "fengsui_heg__aobi_others" },
      skill_name = aobi.name,
      prompt = "#fengsui_heg__aobi-choice",
    })
    player.room:setPlayerMark(player, state_mark, choice)
  end,
})

aobi:addEffect("prohibit", {
  global = true,
  is_prohibited = function(self, from, to, card)
    if not from or not to or not from:hasSkill(aobi.name) then return false end
    local state = from:getMark(state_mark)
    return (state == "fengsui_heg__aobi_self" and to ~= from) or
      (state == "fengsui_heg__aobi_others" and to == from)
  end,
})

aobi:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aobi.name) and
      player:getMark(state_mark) == "fengsui_heg__aobi_self"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, aobi.name)
  end,
})

aobi:addEffect(fk.CardUsing, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(aobi.name) and
      player:getMark(state_mark) == "fengsui_heg__aobi_others" and
      data.card and data.card.suit ~= Card.NoSuit and
      player:getMark("fengsui_heg__aobi_suit_" .. data.card.suit .. "-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "fengsui_heg__aobi_suit_" .. data.card.suit .. "-turn", 1)
    player.room:addTableMarkIfNeed(player, "@fengsui_heg__aobi_suits-turn", data.card:getSuitString(true))
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__aobi_first_suit = true
  end,
})

aobi:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(aobi.name) or
      player:getMark(state_mark) ~= "fengsui_heg__aobi_others" or
      not (data.extra_data or {}).fengsui_heg__aobi_first_suit then
      return false
    end
    return #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      skill_name = aobi.name,
      prompt = "#fengsui_heg__aobi-extra:::" .. data.card:toLogString(),
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {to = chosen[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).to)
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__aobi-extra"] = "拗愎：你可以为此牌额外指定一名目标",
  ["@fengsui_heg__aobi_suits-turn"] = "拗愎：",
}

aobi:addEffect(fk.Damage, {
  global = true,
  mute = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(aobi.name) and player:getMark(state_mark) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, damage_mark, 1)
  end,
})

aobi:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aobi.name) and
      player:getMark(state_mark) ~= 0 and player:getMark(damage_mark) == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, aobi.name)
  end,
})

return aobi
