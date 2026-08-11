local fengsui_heg__zenhui = fk.CreateSkill {
  name = "fengsui_heg__zenhui",
}

Fk:loadTranslationTable{
  ["fengsui_heg__zenhui"] = "谮毁",
  [":fengsui_heg__zenhui"] = "你的出牌阶段内限一次，当你使用【杀】或黑色普通锦囊牌指定唯一目标时，你令可以成为此牌目标的另一名其他角色选择一项："..
  "1.交给你一张牌并成为此牌的使用者；2.成为此牌的额外目标。",

  ["#fengsui_heg__zenhui-choose"] = "谮毁：令一名角色选择：交给你一张牌并成为%arg的使用者；或成为此牌的额外目标",
  ["#fengsui_heg__zenhui-give"] = "谮毁：交给 %dest 一张牌以成为此牌使用者，否则你成为此牌额外目标",

  ["$fengsui_heg__zenhui1"] = "你也休想置身事外！",
  ["$fengsui_heg__zenhui2"] = "你可别不识抬举！"
}

fengsui_heg__zenhui:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengsui_heg__zenhui.name) and
      player.phase == Player.Play and player:usedSkillTimes(fengsui_heg__zenhui.name, Player.HistoryPhase) == 0 and
      (data.card.trueName == "slash" or (data.card.color == Card.Black and data.card:isCommonTrick())) and
      #data.use.tos == 1 and
      #data:getExtraTargets({bypass_times = true}) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = fengsui_heg__zenhui.name,
      targets = data:getExtraTargets({bypass_times = true}),
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__zenhui-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:isNude() then
      data:addTarget(to)
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = fengsui_heg__zenhui.name,
        arg2 = data.card:toLogString(),
      }
      return
    end
    local card = room:askToCards(to, {
      skill_name = fengsui_heg__zenhui.name,
      include_equip = true,
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__zenhui-give::"..player.id,
      cancelable = true,
    })
    if #card > 0 then
      room:obtainCard(player, card, false, fk.ReasonGive, to, fengsui_heg__zenhui.name)
      data.from = to
      --room.logic:trigger(fk.PreCardUse, to, data)
    else
      data:addTarget(to)
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = fengsui_heg__zenhui.name,
        arg2 = data.card:toLogString(),
      }
    end
  end,
})

return fengsui_heg__zenhui
