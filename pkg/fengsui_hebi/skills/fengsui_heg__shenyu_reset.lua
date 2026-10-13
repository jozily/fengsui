local s = fk.CreateSkill { name = "fengsui_heg__shenyu_reset" }
s:addEffect(fk.TurnStart, { global = true,
  can_refresh = function(self, _, target)
    return target and (target:getMark("fengsui_heg__shenyu-turn") > 0 or target:getMark("fengsui_heg__shenyu-discard") > 0 or target:getMark("fengsui_heg__qiju-turn") > 0 or target:getMark("fengsui_heg__quchi_empty-turn") > 0)
  end,
  on_refresh = function(self, _, target)
    local room = target.room
    room:setPlayerMark(target, "fengsui_heg__shenyu-turn", 0)
    room:setPlayerMark(target, "fengsui_heg__shenyu-discard", 0)
    room:setPlayerMark(target, "fengsui_heg__qiju-turn", 0)
    room:setPlayerMark(target, "fengsui_heg__quchi_empty-turn", 0)
  end,
})
return s
