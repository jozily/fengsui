local yangzhi = fk.CreateSkill { name = "fengsui_limited_heg__yangzhi" }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__yangzhi"] = "仰止",
  [":fengsui_limited_heg__yangzhi"] = "当你首次明置此武将牌后，你获得一枚<a href=':fengsui_heg_ascend_skill&'>“升”</a>和一枚<a href=':fengsui_heg__descend_skill&'>“降”</a>。",
  ["fengsui_heg_ascend"] = "升",
  ["@!!fengsui_heg_ascend"] = "升",
  [":@!!fengsui_heg_ascend"] = "出牌阶段，弃置此标记，回复1点体力。",
  ["fengsui_heg__descend"] = "降",
  ["@!!fengsui_heg__descend"] = "降",
  [":@!!fengsui_heg__descend"] = "出牌阶段，弃置此标记，失去1点体力。",
  ["fengsui_limited_heg__yangzhi_ascend"] = "使用“升”",
  ["fengsui_limited_heg__yangzhi_descend"] = "使用“降”",
}

yangzhi:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangzhi.name) and
      player:getMark("fengsui_limited_heg__yangzhi_revealed") == 0 and
      (data.m == "fengsui_limited_heg__qinshimd" or data.d == "fengsui_limited_heg__qinshimd")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fengsui_limited_heg__yangzhi_revealed", 1)
    room:addPlayerMark(player, "@!!fengsui_heg_ascend")
    room:handleAddLoseSkills(player, "fengsui_heg_ascend_skill&")
    room:addPlayerMark(player, "@!!fengsui_heg__descend")
    room:handleAddLoseSkills(player, "fengsui_heg__descend_skill&")
    room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_limited_heg__yangzhi")
  end,
})

return yangzhi
