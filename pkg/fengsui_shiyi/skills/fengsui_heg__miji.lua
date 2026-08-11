local miji = fk.CreateSkill {
  name = "fengsui_heg__miji",
}

Fk:loadTranslationTable{
  ["fengsui_heg__miji"] = "秘计",
  [":fengsui_heg__miji"] = "当一名角色失去体力后，你可以选择一项：1.摸一张牌，令当前回合角色本回合手牌上限+1；2.弃置一张牌，令当前回合角色本回合手牌上限-1。",

  ["fengsui_heg__miji_draw"] = "摸一张牌，令当前回合角色本回合手牌上限+1",
  ["fengsui_heg__miji_discard"] = "弃置一张牌，令当前回合角色本回合手牌上限-1",

  ["$fengsui_heg__miji1"] = "共勉卒勋，不可顺逆转之意。",
  ["$fengsui_heg__miji2"] = "管仲入齐，立九合之功。",
}

miji:addEffect(fk.HpLost, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(miji.name) and player.room.current and not player.room.current.dead
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"fengsui_heg__miji_draw", "Cancel"}
    if not player:isNude() then
      table.insert(choices, 2, "fengsui_heg__miji_discard")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = miji.name,
      all_choices = {"fengsui_heg__miji_draw", "fengsui_heg__miji_discard", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room.current
    if not current or current.dead then return end
    if event:getCostData(self).choice == "fengsui_heg__miji_draw" then
      player:drawCards(1, miji.name)
      room:addPlayerMark(current, MarkEnum.AddMaxCardsInTurn, 1)
    else
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = miji.name,
        cancelable = false,
      })
      room:addPlayerMark(current, MarkEnum.MinusMaxCardsInTurn, 1)
    end
  end,
})

return miji
