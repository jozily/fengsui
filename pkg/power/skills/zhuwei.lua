local zhuwei = fk.CreateSkill{
  name = "ld__zhuwei",
}

Fk:loadTranslationTable{
  ["ld__zhuwei"] = "筑围",
  [":ld__zhuwei"] = "当你的判定结果确定后，若为【杀】或【决斗】，你可以获得之，然后你可以令当前回合角色本回合手牌上限和使用【杀】的次数上限+1。",

  ["#ld__zhuwei-invoke"] = "筑围：是否令 %dest 本回合手牌上限和使用【杀】次数上限+1？",

  ["$ld__zhuwei1"] = "背水一战，只为破敌。",
  ["$ld__zhuwei2"] = "全线并进，连战克晋。",
}

zhuwei:addEffect(fk.FinishJudge, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuwei.name) and
      data.card and table.contains({"slash", "duel"}, data.card.trueName) and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, zhuwei.name)
    if player.dead or room:getCurrent() == nil or room:getCurrent().dead then return end
    if room:askToSkillInvoke(player, {
      skill_name = zhuwei.name,
      prompt = "#ld__zhuwei-invoke"
    }) then
      room:addPlayerMark(room:getCurrent(), MarkEnum.SlashResidue.."-turn", 1)
      room:addPlayerMark(room:getCurrent(), MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,
})

return zhuwei
