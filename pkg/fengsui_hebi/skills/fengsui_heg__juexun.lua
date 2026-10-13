local juexun = fk.CreateSkill { name = "fengsui_heg__juexun" }

local function lostAllHand(data, player)
  return table.find(data or {}, function(move)
    return move.from == player and move.moveInfo and
      table.find(move.moveInfo, function(info) return info.fromArea == Card.PlayerHand end) ~= nil
  end) ~= nil
end

juexun:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, _, _, player, data)
    return player:hasShownSkill(juexun.name) and player:getHandcardNum() == 0 and
      player:getMark("fengsui_heg__juexun_ready") == 0 and lostAllHand(data, player)
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = juexun.name, prompt = "#fengsui_heg__juexun-invoke",
    })
  end,
  on_use = function(self, _, _, player)
    player.room:setPlayerMark(player, "fengsui_heg__juexun_ready", 1)
  end,
})

-- 绝殉标记的下一次全场伤害，不限伤害来源或受伤角色。
juexun:addEffect(fk.PreDamage, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return player:getMark("fengsui_heg__juexun_ready") > 0 and data and data.damage
  end,
  on_use = function(self, _, target, player, data)
    data.damageType = fk.FireDamage
    data.extra_data = data.extra_data or {}
    data.extra_data.fengsui_heg__juexun_owner = player.id
    player.room:setPlayerMark(player, "fengsui_heg__juexun_ready", 0)
  end,
})

juexun:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target == player and data and data.extra_data and
      data.extra_data.fengsui_heg__juexun_owner == player.id and
      data.damageType == fk.FireDamage
  end,
  on_use = function(self, _, _, player)
    player:drawCards(2, juexun.name)
    player:setChainState(true)
  end,
})

-- 若本回合没有造成伤害，待命状态也只保留到本回合结束。
juexun:addEffect(fk.TurnEnd, {
  global = true,
  can_refresh = function(self, _, target)
    return target ~= nil
  end,
  on_refresh = function(self, _, target)
    for _, p in ipairs(target.room.alive_players) do
      target.room:setPlayerMark(p, "fengsui_heg__juexun_ready", 0)
    end
  end,
})

juexun:addTest(function(room, me)
  lu.assertTrue(lostAllHand({{from = me, moveInfo = {{fromArea = Card.PlayerHand}}}}, me))
  lu.assertFalse(lostAllHand({{from = me, moveInfo = {{fromArea = Card.PlayerEquip}}}}, me))
end)

return juexun
