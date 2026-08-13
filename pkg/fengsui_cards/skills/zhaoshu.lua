local skill = fk.CreateSkill {
  name = "heg_zhaoshu_skill"
}

Fk:loadTranslationTable {
  ["heg_zhaoshu"] = "诏书",
  [":heg_zhaoshu"] = "装备牌·宝物<br /><b>宝物技能</b>：当【敕令】移出游戏后，将【诏书】 置入牌堆底。" ..
  "<br />与你势力相同的角色的出牌阶段限一次,其可以将一张(小势力角色改为至多两张)手牌置于【诏书】上。" ..
  "<br />出牌阶段限一次，若【诏书】上有四张花色均不同的牌，你可以将【诏书】上所有的牌置入弃牌堆，然后随机获得一张势力锦囊。" ..
  "<br />※此牌因使用而进入弃牌堆前，改为将此牌移出游戏。" ..
  "<br />※拥有【诏书】的人死亡后， 【诏书】重新置入牌堆底。",

  ["#zhaoshu_base"] = "诏书：使用【诏书】",
  ["#zhaoshuRemoved"] = "%card <b><font color=\"#DC143C\">移出游戏<b>",
}

skill:addEffect("cardskill", {
  prompt = "#zhaoshu_base",
  can_use = Util.CanUseToSelf,
  mod_target_filter = Util.TrueFunc,
})

Fk:addQmlMark {
  name = "zhaoshu",
  how_to_show = function(name, value, p)
    local suits = {}
    for _, id in ipairs(p:getPile("@[zhaoshu]")) do
      local c = Fk:getCardById(id)
      if c.name ~= "heg_zhaoshu" then
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
    end
    return table.concat(table.map(suits, function(suit)
      return Fk:translate(Card.getSuitString({ suit = suit }, true))
    end), " ")
  end,
  qml_path = "packages/utility/qml/ViewPile",
  qml_data = function(name, value, p)
    local ids = {}
    for _, id in ipairs(p:getPile("@[zhaoshu]")) do
      local c = Fk:getCardById(id)
      if c.name ~= "heg_zhaoshu" then
        table.insertIfNeed(ids, id)
      end
    end
    return ids
  end,
}

--用诏书放头上
skill:addEffect(fk.BeforeCardsMove, {
  global = true,
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    if player.room:getTag("hegzhaoshuRemoved") then return false end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "heg_zhaoshu" then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local ids = {}
    local mirror_moves = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerEquip then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id).name == "heg_zhaoshu" then
            table.insert(mirror_info, info)
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #mirror_info > 0 then
          move.moveInfo = move_info
          local mirror_move = move:copy()
          mirror_move.to = player
          mirror_move.toArea = Card.PlayerSpecial
          mirror_move.moveInfo = mirror_info
          mirror_move.moveVisible = true
          mirror_move.moveReason = fk.ReasonJustMove
          mirror_move.specialName = "@[zhaoshu]"
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    table.insertTable(data, mirror_moves)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId).sub_type == Card.SubtypeTreasure then
            player.room:cancelMove(data, { info.cardId })
            print(info.cardId)
          end
        end
      end
    end
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    if player.room:getTag("hegzhaoshuRemoved") then return false end
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerSpecial and move.specialName == "@[zhaoshu]" then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "heg_zhaoshu" then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setTag("hegzhaoshuRemoved", true)
    if not player.dead then
      room:handleAddLoseSkills(player, "zhaoshu_yuan")
      room:handleAddLoseSkills(player, "heg_zhaoshu_other&")
    end
  end,
})

return skill
