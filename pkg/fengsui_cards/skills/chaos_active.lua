local skill = fk.CreateSkill{
  name = "#heg_chaos_active",
}

Fk:loadTranslationTable{
  ["#heg_chaos_active"] = "文和乱武",
}

skill:addEffect("active",{
  mute = true,
  card_num = 2,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return table.every(selected, function(id) return Fk:getCardById(to_select).type ~= Fk:getCardById(id).type end)
    and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
})

return skill