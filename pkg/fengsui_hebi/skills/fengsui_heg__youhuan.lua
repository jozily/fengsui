local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local youhuan = fk.CreateSkill { name = "fengsui_heg__youhuan", tags = { Skill.Compulsory } }

youhuan:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, _, target, player, data)
    return target and player:hasSkill(self.name) and data and data.from and
      H.compareKingdomWith(player, data.from) and H.getGeneralsRevealedNum(player) == 2
  end,
  on_use = function(self, _, _, player, data)
    local place = U.getSkillPlace(player, self.name)
    if place ~= nil then player:hideGeneral(place) end
    data:changeDamage(-1)
    return data.damage <= 0
  end,
})

return youhuan
