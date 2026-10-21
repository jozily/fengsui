local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local xiarong = fk.CreateSkill { name = "fengsui_heg__xiarong" }

xiarong:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, _, target, player)
    return player:hasShownSkill(self.name) and target and H.compareKingdomWith(player, target) and
      H.getGeneralsRevealedNum(player) == 2 and H.getGeneralsRevealedNum(target) == 2
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local place = U.getSkillPlace(player, self.name)
    if place == nil then return end
    player:hideGeneral(place)
    if target ~= player then
      local choice = room:askToChoice(target, {
        choices = { "fengsui_heg__xiarong_main", "fengsui_heg__xiarong_deputy" },
        skill_name = self.name,
      })
      target:hideGeneral(choice == "fengsui_heg__xiarong_deputy")
    end
    if target:isAlive() then
      room:recover { who = target, num = 1, recoverBy = player, skillName = self.name }
    end
    if data and data.from and not player.dead and
      not data.from:inMyAttackRange(player) and not data.from:inMyAttackRange(target) then
      player:revealGeneral(place)
    end
  end,
})

return xiarong
