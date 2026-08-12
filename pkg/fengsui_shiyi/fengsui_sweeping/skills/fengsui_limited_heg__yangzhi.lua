local yangzhi = fk.CreateSkill { name = "fengsui_limited_heg__yangzhi" }

Fk:loadTranslationTable {
  ["fengsui_limited_heg__yangzhi"] = "仰止",
  [":fengsui_limited_heg__yangzhi"] = "当你首次明置此武将牌后，你获得一枚“升”和一枚“降”。出牌阶段，你可以弃对应标记令体力值上升或下降1点。",
  ["fengsui_heg_ascend"] = "升",
  ["@fengsui_heg_ascend"] = "升",
  [":@fengsui_heg_ascend"] = "出牌阶段，弃置此标记，回复1点体力。",
  ["fengsui_heg__descend"] = "降",
  ["@fengsui_heg__descend"] = "降",
  [":@fengsui_heg__descend"] = "出牌阶段，弃置此标记，失去1点体力。",
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
    room:addPlayerMark(player, "@fengsui_heg_ascend")
    room:addPlayerMark(player, "@fengsui_heg__descend")
  end,
})

yangzhi:addEffect("active", {
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    local choices = {}
    if player:getMark("@fengsui_heg_ascend") > 0 and player:isWounded() then
      table.insert(choices, "fengsui_limited_heg__yangzhi_ascend")
    end
    if player:getMark("@fengsui_heg__descend") > 0 then
      table.insert(choices, "fengsui_limited_heg__yangzhi_descend")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return (player:getMark("@fengsui_heg_ascend") > 0 and player:isWounded()) or
      player:getMark("@fengsui_heg__descend") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local choice = self.interaction.data
    if choice == "fengsui_limited_heg__yangzhi_ascend" then
      room:removePlayerMark(player, "@fengsui_heg_ascend")
      room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_heg__ascend")
      room:recover { who = player, num = 1, recoverBy = player, skillName = yangzhi.name }
    elseif choice == "fengsui_limited_heg__yangzhi_descend" then
      room:removePlayerMark(player, "@fengsui_heg__descend")
      room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_heg__descend")
      room:loseHp(player, 1, yangzhi.name)
    end
  end,
})

return yangzhi
