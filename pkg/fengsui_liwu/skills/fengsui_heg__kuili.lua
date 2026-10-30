local H = require "packages.fengsui.hegemony_util"

local kuili = fk.CreateSkill {
  name = "fengsui_heg__kuili",
  tags = { Skill.Compulsory },
}

kuili:addEffect(fk.Death, {
  can_trigger = function(self, _, target, player)
    local mark = target and target:getMark("@fengsui_heg__tiaomu")
    return target and target ~= player and mark ~= nil and mark ~= 0 and mark ~= "" and
      player:hasSkill(kuili.name, true)
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local place = H.inGeneralSkills(player, kuili.name)
    if not place then return end
    if place == "d" then
      H.transformGeneral(room, player, false, false, 1, kuili.name)
    else
      H.removeGeneral(player, false, kuili.name)
    end
  end,
})

return kuili
