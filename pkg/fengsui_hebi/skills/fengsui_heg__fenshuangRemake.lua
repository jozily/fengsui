local H = require "packages.fengsui.hegemony_util"

local fenshuang = fk.CreateSkill{
  name = "fengsui_heg__fenshuangRemake",
}

fenshuang:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#fengsui_heg__fenshuangRemake-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(fenshuang.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:inMyAttackRange(player)
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    local mark_name = "fengsui_heg__fenshuangRemake_proxy-round"
    room:addTableMark(player, mark_name, target.id)
    local damaged = room:damage{
      from = target,
      to = player,
      damage = 1,
      skillName = fenshuang.name,
    }
    if not damaged or player.dead then
      local proxies = player:getTableMark(mark_name)
      table.remove(proxies)
      room:setPlayerMark(player, mark_name, #proxies > 0 and proxies or 0)
    end
  end,
})

fenshuang:addEffect(H.CommandExecuting, {
  global = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      #player:getTableMark("fengsui_heg__fenshuangRemake_proxy-round") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local proxies = player:getTableMark("fengsui_heg__fenshuangRemake_proxy-round")
    local new_to = room:getPlayerById(proxies[1])
    table.remove(proxies, 1)
    room:setPlayerMark(player, "fengsui_heg__fenshuangRemake_proxy-round",
      #proxies > 0 and proxies or 0)
    if new_to and new_to:isAlive() then
      room:sendLog{
        type = "#FenshuangTransfer",
        from = player.id,
        to = {new_to.id},
        arg = fenshuang.name,
      }
      data.succeed = true
      table.insertIfNeed(data.succeed_list, new_to)
      H.CommandCB(data.command, new_to, data.from, data)
      return true
    end
  end,
})

return fenshuang
