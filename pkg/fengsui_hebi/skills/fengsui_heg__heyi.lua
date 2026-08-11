local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local heyi = fk.CreateSkill{
  name = "fengsui_heg__heyi",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(heyi.name) or not data.from or
      (target ~= player and data.from ~= player) then return false end
    return table.find(player.room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, data.from) and not p:isNude() and
        #player:getCardIds("he") + 1 >= data.damage
    end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, data.from) and not p:isNude()
    end)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = targets, min_num = 1, max_num = 1, skill_name = heyi.name,
      prompt = "#fengsui_heg__heyi-choose::" .. data.from.id .. ":" .. data.damage,
      cancelable = true,
    })
    if #chosen > 0 then event:setCostData(self, { to = chosen[1] }); return true end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    if to.dead or to:isNude() then return end
    local id = room:askToChooseCard(player, { target = to, flag = "he", skill_name = heyi.name })
    room:obtainCard(player, id, false, fk.ReasonPrey, player, heyi.name)
    if player.dead or to.dead then return end
    local n = math.min(data.damage, #player:getCardIds("he"))
    if n == 0 then return end
    local cards = U.chooseCardsFromList(room, player, player:getCardIds("he"), n, n,
      "#fengsui_heg__heyi-give::" .. to.id .. ":" .. n, heyi.name, false)
    if #cards == n then room:obtainCard(to, cards, false, fk.ReasonGive, player, heyi.name) end
  end,
}

heyi:addEffect(fk.Damaged, spec)
heyi:addEffect(fk.Damage, spec)

return heyi
