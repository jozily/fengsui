local jiejie = fk.CreateSkill {
  name = "fengsui_heg__jiejie",
}

Fk:loadTranslationTable{
  ["fengsui_heg__jiejie"] = "诫节",
  [":fengsui_heg__jiejie"] = "摸牌阶段开始时，你可以选择一项：1.手牌上限+1，本回合你不能对其他角色使用牌；2.回复1点体力，本回合你不能对自己使用牌。",

  ["fengsui_heg__jiejie_maxcards"] = "手牌上限+1，本回合不能对其他角色用牌",
  ["fengsui_heg__jiejie_recover"] = "回复1点体力，本回合不能对自己用牌",

  ["$fengsui_heg__jiejie1"] = "为谋大计，失小利亦无妨。",
  ["$fengsui_heg__jiejie2"] = "才思敏捷，方可识人喻事。",
}

jiejie:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiejie.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {
      "fengsui_heg__jiejie_maxcards",
      "fengsui_heg__jiejie_recover",
      "Cancel",
    }
    local choices = table.simpleClone(all_choices)
    if not player:isWounded() then
      table.remove(choices, 2)
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = jiejie.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "fengsui_heg__jiejie_maxcards" then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      room:recover{
        who = player,
        num = 1,
        skillName = jiejie.name,
      }
    end
  end,
})

jiejie:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if not card or not from then return false end
    if from:getMark("fengsui_heg__jiejie_maxcards-turn") > 0 and from ~= to then
      return true
    end
    if from:getMark("fengsui_heg__jiejie_recover-turn") > 0 and from == to then
      return true
    end
  end,
})

return jiejie
