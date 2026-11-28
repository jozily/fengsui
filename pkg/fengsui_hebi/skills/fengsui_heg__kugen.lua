-- 枯根（残愠衍生）
-- 锁定技，你变更副将后失去一点体力值。
local H = require "packages.fengsui.hegemony_util"

local kugen = fk.CreateSkill {
  name = "fengsui_heg__kugen",
  tags = { Skill.Compulsory },
}

-- 变更副将后：GeneralTransformed 由 H.transformGeneral 在 changeHero 之后触发。
-- data.isMain 为 true 时是主将变更，这里只处理副将。
kugen:addEffect(H.GeneralTransformed, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kugen.name, false, true)
      and data and not data.isMain and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, kugen.name)
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__kugen"] = "枯根",
  [":fengsui_heg__kugen"] = "锁定技，你变更副将后失去一点体力值。",
}

return kugen
