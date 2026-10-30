local neutralRule = require "packages.fengsui.pkg.fengsui_liwu.skills._fengsui_neutral_rule"

local warlordsRule = fk.CreateSkill {
  name = "#fengsui_heg__warlords_rule",
  mute = true,
  no_indicate = true,
  global = true,
}

warlordsRule:addEffect(fk.GeneralShown, {
  global = true,
  priority = 20,
  can_trigger = neutralRule.warlordsCanTrigger,
  on_cost = function() return true end,
  on_use = neutralRule.warlordsOnUse,
})

warlordsRule:addEffect(fk.GeneralRevealed, {
  global = true,
  priority = 20,
  can_trigger = neutralRule.warlordsCanTrigger,
  on_cost = function() return true end,
  on_use = neutralRule.warlordsOnUse,
})

return warlordsRule
