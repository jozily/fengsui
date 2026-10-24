local H = require "packages.fengsui.hegemony_util"

local kuili = fk.CreateSkill {
  name = "fengsui_heg__kuili",
  tags = { Skill.Compulsory },
}

kuili:addEffect(fk.Death, {
  can_trigger = function(self, _, target, player)
    local mark = target and target:getMark("@fengsui_heg__tiaomu")
    return target and target ~= player and mark ~= nil and mark ~= 0 and mark ~= "" and
      player:hasShownSkill(kuili.name)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local place = H.inGeneralSkills(player, kuili.name)
    if not place then return end
    if H.allGeneralsRevealed(player) then
      player:hideGeneral(place == "d")
    else
      H.removeGeneral(player, place == "d", kuili.name)
    end
  end,
})

return kuili
