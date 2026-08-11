local H = require "packages.fengsui.hegemony_util"

local caixia = fk.CreateSkill{
  name = "fengsui_heg__caixia",
}

local caixia_trigger = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(caixia.name) and H.allGeneralsRevealed(player) and
      (target == player or data.from == player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = caixia.name,
      prompt = "#fengsui_heg__caixia-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
    end)
    player:drawCards(n, caixia.name)
    if player:isAlive() then
      H.doHideGeneral(room, player, player, caixia.name)
    end
  end,
}

caixia:addEffect(fk.Damaged, caixia_trigger)
caixia:addEffect(fk.Damage, caixia_trigger)

return caixia
