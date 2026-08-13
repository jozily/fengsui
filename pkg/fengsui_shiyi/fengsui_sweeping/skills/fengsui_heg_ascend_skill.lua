local ascend = fk.CreateSkill { name = "fengsui_heg_ascend_skill&" }

ascend:addEffect("active", {
  anim_type = "recover",
  prompt = "#fengsui_heg_ascend_skill&",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("@!!fengsui_heg_ascend") > 0 and player:isWounded()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:removePlayerMark(player, "@!!fengsui_heg_ascend")
    if player:getMark("@!!fengsui_heg_ascend") == 0 then
      room:handleAddLoseSkills(player, "-fengsui_heg_ascend_skill&")
    end
    room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_heg__ascend")
    room:recover { who = player, num = 1, recoverBy = player, skillName = ascend.name }
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg_ascend_skill&"] = "升",
  ["#fengsui_heg_ascend_skill&"] = "你可弃一枚“升”，回复1点体力",
  [":fengsui_heg_ascend_skill&"] = "出牌阶段，你可弃一枚“升”，回复1点体力。",
}

return ascend
