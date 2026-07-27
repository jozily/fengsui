local H = require "packages.hegemony.util"

local guru = fk.CreateSkill{
  name = "fengsui_heg__guru",
  tags = { Skill.Compulsory },
}

guru:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(guru.name) and
      player:hasShownSkill(guru.name) and H.getGeneralsRevealedNum(player) == 1
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + H.getSameKingdomPlayersNum(player.room, player)
  end,
})

guru:addEffect("distance", {
  correct_func = function(self, from, to)
    if not from:hasSkill(guru.name) or not H.allGeneralsRevealed(from) then return 0 end
    local same = H.getSameKingdomPlayersNum(from.room, from)
    local kingdoms = 0
    for _, count in pairs(H.getKingdomPlayersNum(from.room)) do
      if count > 0 then kingdoms = kingdoms + 1 end
    end
    return same < kingdoms and same or 0
  end,
})

return guru
