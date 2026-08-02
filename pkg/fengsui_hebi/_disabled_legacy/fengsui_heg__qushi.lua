local fengsui_heg__qushi = fk.CreateSkill{
  name = "fengsui_heg__qushi",
}

fengsui_heg__qushi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    -- TODO
  end,
})

return fengsui_heg__qushi
