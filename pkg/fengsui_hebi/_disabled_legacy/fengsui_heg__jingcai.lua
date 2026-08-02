local fengsui_heg__jingcai = fk.CreateSkill{
  name = "fengsui_heg__jingcai",
}

fengsui_heg__jingcai:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    -- TODO
  end,
})

return fengsui_heg__jingcai
