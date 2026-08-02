local chenji = fk.CreateSkill{
  name = "fengsui_heg__chenji",
  tags = {Skill.Compulsory, Skill.MainPlace},
}

local function markCount(player)
  return player:getMark("@!!vanguard") + player:getMark("@!!yinyangfish") +
    player:getMark("@!!companion") + player:getMark("@!!wild")
end

local spec = {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenji.name) and markCount(player) > #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    player.room:killPlayer{who = player}
  end,
}

chenji:addEffect(fk.EventAcquireSkill, spec)
chenji:addEffect(fk.AfterCardsMove, spec)
chenji:addEffect(fk.EventPhaseStart, spec)
chenji:addEffect(fk.CardUseFinished, spec)

return chenji
