local H = require "packages.fengsui.hegemony_util"

local junshi = fk.CreateSkill{name = "fengsui_limited_heg__junshi", tags = { Skill.Compulsory }}

Fk:loadTranslationTable{
  ["fengsui_limited_heg__junshi"] = "钧世",
  [":fengsui_limited_heg__junshi"] = "锁定技，有角色受到雷电伤害后，若其势力与你不同，你摸一张牌。",
}

junshi:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(junshi.name) and data.damageType == fk.ThunderDamage and
      target and target:isAlive() and not H.compareKingdomWith(player, target)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, junshi.name)
  end,
})

return junshi
