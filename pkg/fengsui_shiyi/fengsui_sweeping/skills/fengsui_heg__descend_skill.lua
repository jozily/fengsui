local descend = fk.CreateSkill { name = "fengsui_heg__descend_skill&" }

descend:addEffect("active", {
  anim_type = "negative",
  prompt = "#fengsui_heg__descend_skill&",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("@!!fengsui_heg__descend") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:removePlayerMark(player, "@!!fengsui_heg__descend")
    if player:getMark("@!!fengsui_heg__descend") == 0 then
      room:handleAddLoseSkills(player, "-fengsui_heg__descend_skill&")
    end
    room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_heg__descend")
    room:loseHp(player, 1, descend.name)
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__descend_skill&"] = "降",
  ["#fengsui_heg__descend_skill&"] = "你可弃一枚“降”，失去1点体力",
  [":fengsui_heg__descend_skill&"] = "出牌阶段，你可弃一枚“降”，失去1点体力。",
}

return descend
