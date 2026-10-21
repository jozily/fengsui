local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local xiarong = fk.CreateSkill { name = "fengsui_heg__xiarongRemake" }
xiarong:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, _, target, player)
    return player:hasShownSkill(self.name) and target ~= nil and target ~= player
      and H.compareKingdomWith(player, target)
      and H.getGeneralsRevealedNum(player) == 2
      and H.getGeneralsRevealedNum(target) == 2
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local place = U.getSkillPlace(player, self.name)
    if place ~= nil then player:hideGeneral(place) end
    local hidden = room:askToChoice(target, { choices = { "fengsui_heg__xiarongRemake_main", "fengsui_heg__xiarongRemake_deputy" }, skill_name = self.name })
    target:hideGeneral(hidden == "fengsui_heg__xiarongRemake_deputy")
    if not target.dead then
      room:recover { who = target, num = 1, recoverBy = player, skillName = self.name }
    end
    if data and data.from and not player.dead
      and not data.from:inMyAttackRange(player) and not data.from:inMyAttackRange(target) then
      -- 暗置后重新明置发动技能的同一张武将牌。
      if place ~= nil then player:revealGeneral(place) end
    end
  end,
})
return xiarong
