local duxin = fk.CreateSkill{name = "fengsui_limited_heg__duxin"}

Fk:loadTranslationTable{
  ["fengsui_limited_heg__duxin"] = "读心",
  [":fengsui_limited_heg__duxin"] = "当你明置或暗置武将牌时，你可以视为使用一张【知己知彼】。",
  ["#fengsui_limited_heg__duxin-use"] = "读心：你可以视为使用一张【知己知彼】",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duxin.name, true) and table.find(player.room.alive_players, function(p)
      return p ~= player and player:canUseTo(Fk:cloneCard("known_both"), p)
    end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = duxin.name })
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToUseVirtualCard(player, {
      name = "known_both", skill_name = duxin.name,
      prompt = "#fengsui_limited_heg__duxin-use", cancelable = false,
    })
  end,
}
duxin:addEffect(fk.GeneralRevealed, spec)
duxin:addEffect(fk.GeneralHidden, spec)

return duxin
