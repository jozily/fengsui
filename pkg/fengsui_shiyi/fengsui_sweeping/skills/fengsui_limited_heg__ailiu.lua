local ailiu = fk.CreateSkill { name = "fengsui_limited_heg__ailiu", tags = { Skill.Compulsory } }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__ailiu"] = "爱六",
  [":fengsui_limited_heg__ailiu"] = "锁定技，你使用基本牌或普通锦囊牌时需进行判定，若结果小于6，则此牌随机额外指定一名合法目标。",
}

ailiu:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ailiu.name) and data.card and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #data:getExtraTargets() > 0
  end,
  on_use = function(self, event, target, player, data)
    local judge = { who = player, reason = ailiu.name, pattern = "." }
    player.room:judge(judge)
    if judge.card and judge.card.number < 6 then
      local extras = data:getExtraTargets()
      if #extras > 0 then data:addTarget(table.random(extras)) end
    end
  end,
})

return ailiu
