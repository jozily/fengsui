local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local xiarong = fk.CreateSkill { name = "fengsui_heg__xiarong" }
xiarong:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, _, target, player)
    return player:hasSkill(self.name) and target ~= nil and target ~= player
      and H.compareKingdomWith(player, target)
      and player.general ~= "anjiang" and player.deputyGeneral ~= "anjiang"
      and target.general ~= "anjiang" and target.deputyGeneral ~= "anjiang"
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    room:recover { who = target, num = 1, recoverBy = player, skillName = self.name }
    local place = U.getSkillPlace(player, self.name)
    if place ~= nil then player:hideGeneral(place) end
    local hidden = room:askToChoice(target, { choices = { "fengsui_heg__xiarong_main", "fengsui_heg__xiarong_deputy" }, skill_name = self.name })
    target:hideGeneral(hidden == "fengsui_heg__xiarong_deputy")
    if data and data.from and data.from ~= player and data.from ~= target
      and player:distanceTo(data.from) > 1 and target:distanceTo(data.from) > 1 then
      if player.general == "anjiang" then player:revealGeneral(false) end
      if player.deputyGeneral == "anjiang" then player:revealGeneral(true) end
    end
  end,
})
return xiarong
