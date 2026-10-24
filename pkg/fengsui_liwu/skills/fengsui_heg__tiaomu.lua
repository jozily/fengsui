local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_liwu.util"
local tiaomu = fk.CreateSkill {
  name = "fengsui_heg__tiaomu",
  tags = { Skill.Compulsory },
}
local target_mark = "@fengsui_heg__tiaomu"

tiaomu:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(tiaomu.name) and data.use and data.from and
      H.allGeneralsRevealed(player) and
      not data.from:inMyAttackRange(player)
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local place = U.getSkillPlace(player, tiaomu.name)
    if place == nil then return end
    player:hideGeneral(not place)
    room:drawCards(data.from, 1, tiaomu.name)
    data:setNullified(player)
    room:setPlayerMark(data.from, target_mark, "迢目")
  end,
})

return tiaomu
