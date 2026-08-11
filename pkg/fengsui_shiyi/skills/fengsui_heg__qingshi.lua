local H = require "packages.fengsui.hegemony_util"

local qingshi = fk.CreateSkill {
  name = "fengsui_heg__qingshi",
}

Fk:loadTranslationTable{
  ["fengsui_heg__qingshi"] = "清识",
  [":fengsui_heg__qingshi"] = "当你受到伤害后，你可以选择一名角色，若你与其势力：相同，你与其各摸一张牌；不同，你弃置你与其各一张牌。",
  ["#fengsui_heg__qingshi-invoke"] = "清识：选择一名角色；同势力则各摸一张牌，不同势力则弃置你与其各一张牌",

  ["$fengsui_heg__qingshi1"] = "行路八千里，方可辨忠奸。",
  ["$fengsui_heg__qingshi2"] = "观其行，明其志，而后知心。",
}

qingshi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingshi.name)
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = player.room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__qingshi-invoke",
      skill_name = qingshi.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if H.compareKingdomWith(player, to) then
      player:drawCards(1, qingshi.name)
      if to:isAlive() then to:drawCards(1, qingshi.name) end
      return
    end
    if not player:isNude() then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = qingshi.name,
        cancelable = false,
      })
    end
    if to:isAlive() and not to:isNude() then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = qingshi.name,
      })
      room:throwCard(id, qingshi.name, to, player)
    end
  end,
})

return qingshi
