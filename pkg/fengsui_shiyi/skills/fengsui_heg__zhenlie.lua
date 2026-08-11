local zhenlie = fk.CreateSkill {
  name = "fengsui_heg__zhenlie",
}

Fk:loadTranslationTable{
  ["fengsui_heg__zhenlie"] = "贞烈",
  [":fengsui_heg__zhenlie"] = "每回合限一次，当你成为其他角色使用单体牌的目标后，你可以失去1点体力，令此牌对你无效，然后你对其发起“军令”。若其不执行，你获得其一张牌。",

  ["#fengsui_heg__zhenlie-invoke"] = "贞烈：是否失去1点体力，令 %dest 使用的%arg对你无效，然后对其发起军令？",

  ["$fengsui_heg__zhenlie1"] = "素颜风吹胭脂折，巾帼红妆贞烈战！",
  ["$fengsui_heg__zhenlie2"] = "贞洁烈志，与城共守。",
}

zhenlie:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenlie.name) and data.from ~= player and
      player:usedSkillTimes(zhenlie.name, Player.HistoryTurn) == 0 and #data.use.tos == 1
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhenlie.name,
      prompt = "#fengsui_heg__zhenlie-invoke::"..data.from.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, zhenlie.name)
    if player.dead then return end
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
    if data.from.dead then return end
    if not H.askToCommand(player, {
      tos = {data.from},
      skill_name = zhenlie.name,
    }) and not data.from:isNude() then
      local id = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = zhenlie.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, zhenlie.name)
    end
  end,
})

return zhenlie
