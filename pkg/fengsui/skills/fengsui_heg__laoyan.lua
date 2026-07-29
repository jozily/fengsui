local H = require "packages.hegemony.util"

local laoyan = fk.CreateSkill{
  name = "fengsui_heg__laoyan",
  tags = { Skill.Compulsory },
}

laoyan:addEffect(fk.CardUsing, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(laoyan.name) and target ~= player and data.card and #data.tos > 1 and table.contains(data.tos, player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local team = {}
    for _, p in ipairs(data.tos) do
       if p ~= player and H.compareKingdomWith(p, player) then table.insert(team, p) end
    end
    if #team > 0 then
       data.nullifiedTargets = data.nullifiedTargets or {}
       table.insertTableIfNeed(data.nullifiedTargets, team)
       data.extra_data = data.extra_data or {}
       data.extra_data.laoyan_trigger = player.id
    end
  end,
})

laoyan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.laoyan_trigger == player.id then
       -- 判断是否没受到伤害
       local hurt = false
       if data.damageDealt and data.damageDealt[player] and data.damageDealt[player] > 0 then hurt = true end
       return not hurt and target ~= player and not H.compareKingdomWith(target, player)
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, laoyan.name)
  end,
})

return laoyan
