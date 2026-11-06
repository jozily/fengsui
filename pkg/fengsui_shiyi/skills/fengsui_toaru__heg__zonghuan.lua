local zonghuan = fk.CreateSkill {
  name = "fengsui_toaru__heg__zonghuan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["fengsui_toaru__heg__zonghuan"] = "纵幻",
  [":fengsui_toaru__heg__zonghuan"] = "限定技，当你成为一张非装备牌的目标后，你可以为此牌重新指定使用者和合法目标。",
  ["#fengsui_toaru__heg__zonghuan-invoke"] = "纵幻：是否为 %dest 使用的牌重新指定使用者和目标？",
  ["#fengsui_toaru__heg__zonghuan-user"] = "纵幻：选择此牌的新使用者",
  ["#fengsui_toaru__heg__zonghuan-target"] = "纵幻：重新指定此牌的合法目标",
}

zonghuan:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, _, target, player, data)
    if target ~= player or not player:hasSkill(zonghuan.name) then return false end
    if player:usedSkillTimes(zonghuan.name, Player.HistoryGame) > 0 then return false end
    if not data or not data.card or data.cancelled then return false end
    if data.card.type == Card.TypeEquip then return false end
    return data.from and data.from:isAlive()
  end,
  on_cost = function(self, _, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zonghuan.name,
      prompt = "#fengsui_toaru__heg__zonghuan-invoke::" .. data.from.id,
    })
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local use = data
    local newUser = room:askToChoosePlayers(player, {
      targets = room.alive_players, min_num = 1, max_num = 1,
      skill_name = zonghuan.name,
      prompt = "#fengsui_toaru__heg__zonghuan-user",
      cancelable = false,
    })[1]
    if not newUser then return end
    use.from = newUser
    -- 清空原目标，重新指定
    local oldTos = {}
    for _, t in ipairs(use.tos) do oldTos[#oldTos + 1] = t end
    for _, t in ipairs(oldTos) do
      if table.contains(use.tos, t) then use:cancelTarget(t) end
    end
    local candidates = table.filter(room.alive_players, function(p)
      return p:isAlive() and newUser:canUseTo(use.card, p, { bypass_distances = true, bypass_times = true })
    end)
    if #candidates == 0 then return end
    local newTos = room:askToChoosePlayers(player, {
      targets = candidates, min_num = 1, max_num = #candidates,
      skill_name = zonghuan.name,
      prompt = "#fengsui_toaru__heg__zonghuan-target",
      cancelable = false,
    })
    for _, p in ipairs(newTos) do
      if p:isAlive() and not table.contains(use.tos, p) then use:addTarget(p) end
    end
  end,
})

return zonghuan
