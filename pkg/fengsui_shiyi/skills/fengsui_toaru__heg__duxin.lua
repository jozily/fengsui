local duxin = fk.CreateSkill{name = "fengsui_toaru__heg__duxin"}

Fk:loadTranslationTable{
  ["fengsui_toaru__heg__duxin"] = "读心",
  [":fengsui_toaru__heg__duxin"] = "当你明置此武将牌或即将暗置此武将牌时，你可以视为使用一张不可响应的【知己知彼】并摸一张牌。",
  ["#fengsui_toaru__heg__duxin-use"] = "读心：你可以视为使用一张【知己知彼】",
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
    local use = player.room:askToUseVirtualCard(player, {
      name = "known_both", skill_name = duxin.name,
      prompt = "#fengsui_toaru__heg__duxin-use", cancelable = false, skip = true,
    })
    if use then
      use.disresponsiveList = player.room.players
      player.room:useCard(use)
      if player:isAlive() then player:drawCards(1, duxin.name) end
    end
  end,
}
duxin:addEffect(fk.GeneralRevealed, spec)
-- 暗置用前置时机：此时武将牌还明着，读心结算完再真正暗置。
-- 挂在 GeneralHidden 上会在暗置完成后触发，技能已被换成 fake skill，
-- 之后再被明置回来又能触发一次，一来一回白拿牌。
if fk.BeforeGeneralHidden then
  duxin:addEffect(fk.BeforeGeneralHidden, spec)
else
  fk.qWarning("[fengsui] fk.BeforeGeneralHidden 未注册，读心回退到 GeneralHidden")
  duxin:addEffect(fk.GeneralHidden, spec)
end

return duxin
