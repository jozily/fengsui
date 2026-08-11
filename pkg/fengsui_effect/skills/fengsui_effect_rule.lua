local effectRule = fk.CreateSkill{
  name = "#fengsui_effect_rule",
}

local root = "packages/fengsui/pkg/fengsui_effect/qml/"

effectRule:addEffect(fk.GeneralRevealed, {
  global = true,
  mute = true,
  priority = 1,
  can_trigger = function(self, event, target, player, data)
    return not Fk._fengsuiNativeHegemonyRevealEffects and
      player.room:getSettings("gameMode") ~= "fengsui_heg__mode" and target == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, generalName in ipairs(data) do
      if room:getTag("TheFirstToShowRewarded") == player.id and player:getMark("_vanguard_gained") == 0 then
        room:doSuperLightBox(root .. "Vanguard.qml")
      end
      local general = Fk.generals[generalName]
      if player:getMark("hasShownMainGeneral") == 1 and general and general.kingdom == "wild" and
          player:getMark("_wild_gained") == 0 then
        room:doSuperLightBox(root .. "WildEffect.qml")
      end
      if player.general ~= "anjiang" and player.deputyGeneral ~= "anjiang" and
          player:getMark("CompanionEffect") > 0 then
        room:doSuperLightBox(root .. "Companion.qml")
      end
    end
  end,
})

return effectRule
