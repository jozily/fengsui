local aobi = fk.CreateSkill{
  name = "fengsui_heg__aobiRemake",
  tags = { Skill.Compulsory },
}

local state_mark = "fengsui_heg__aobiRemake_state-turn"
local damage_mark = "fengsui_heg__aobiRemake_damage-turn"

aobi:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aobi.name)
  end,
  on_use = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "fengsui_heg__aobiRemake_self", "fengsui_heg__aobiRemake_others" },
      skill_name = aobi.name,
      prompt = "#fengsui_heg__aobiRemake-choice",
    })
    player.room:setPlayerMark(player, state_mark, choice)
  end,
})

aobi:addEffect("prohibit", {
  global = true,
  is_prohibited = function(self, from, to, card)
    if not from or not to or not from:hasSkill(aobi.name) then return false end
    local state = from:getMark(state_mark)
    return (state == "fengsui_heg__aobiRemake_self" and to ~= from) or
      (state == "fengsui_heg__aobiRemake_others" and to == from)
  end,
})

aobi:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(aobi.name) and
      player:getMark(state_mark) == "fengsui_heg__aobiRemake_self"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, aobi.name)
  end,
})

aobi:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(aobi.name) or
      player:getMark(state_mark) ~= "fengsui_heg__aobiRemake_others" or
      not data.card or data.card.suit == Card.NoSuit then
      return false
    end
    return player:getMark("fengsui_heg__aobiRemake_suit_" .. data.card.suit .. "-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fengsui_heg__aobiRemake_suit_" .. data.card.suit .. "-turn", 1)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

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
