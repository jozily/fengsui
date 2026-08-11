local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local zeyu = fk.CreateSkill{
  name = "fengsui_heg__zeyuRemake",
}

zeyu:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local damage = data.damage
    if not damage or not damage.from then return false end
    return player:hasSkill(zeyu.name) and H.compareKingdomWith(damage.from, player) and
      not H.compareKingdomWith(target, damage.from)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zeyu.name,
      prompt = "#fengsui_heg__zeyuRemake-invoke::" .. data.damage.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local killer = data.damage.from
    killer:drawCards(2, zeyu.name)

    local choice = room:askToChoice(killer, {
       choices = {"fengsui_heg__zeyuRemake_swap", "fengsui_heg__zeyuRemake_transform"},
       prompt = "#fengsui_heg__zeyuRemake-choice",
    })

    if choice == "fengsui_heg__zeyuRemake_swap" then
       U.swapGenerals(room, killer)
    else
       H.transformGeneral(room, killer, false, false)
    end
  end,
})

return zeyu
