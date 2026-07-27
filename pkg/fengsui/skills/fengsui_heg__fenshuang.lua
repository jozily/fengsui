local H = require "packages.hegemony.util"

local fenshuang = fk.CreateSkill{
  name = "fengsui_heg__fenshuang",
}

fenshuang:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#fengsui_heg__fenshuang-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(fenshuang.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:inMyAttackRange(player)
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    room:damage{from = target, to = player, damage = 1, skillName = fenshuang.name}
    if player:isAlive() then
      room:addTableMark(player, "fengsui_heg__fenshuang_proxy-round", target.id)
    end
  end,
})

fenshuang:addEffect(H.CommandExecuting, {
  global = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return table.contains(data.tos, player) and
      #player:getTableMark("fengsui_heg__fenshuang_proxy-round") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local proxies = player:getTableMark("fengsui_heg__fenshuang_proxy-round")
    local new_to = room:getPlayerById(proxies[1])
    table.remove(proxies, 1)
    room:setPlayerMark(player, "fengsui_heg__fenshuang_proxy-round",
      #proxies > 0 and proxies or 0)
    if new_to and new_to:isAlive() then
      table.removeOne(data.tos, player)
      table.insertIfNeed(data.tos, new_to)
      room:sendLog{
        type = "#FenshuangTransfer",
        from = player.id,
        to = {new_to.id},
        arg = fenshuang.name,
      }
    end
  end,
})

return fenshuang
