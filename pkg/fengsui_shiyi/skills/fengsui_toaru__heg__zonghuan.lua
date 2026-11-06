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
    -- data 是 AimData（aimStruct），use.use 才是真正的 UseCardData；
    -- 两边的 from 都要改：aimStruct.from 由引擎同步回 useCardData.from。
    local useData = use.use or use
    local oldUser = useData.from
    local newUser = room:askToChoosePlayers(player, {
      targets = room.alive_players, min_num = 1, max_num = 1,
      skill_name = zonghuan.name,
      prompt = "#fengsui_toaru__heg__zonghuan-user",
      cancelable = false,
    })[1]
    if not newUser then return end
    use.from = newUser
    useData.from = newUser
    -- use.tos 是 AimGroup（1=未结算 2=已结算 3=已取消 三个子列表）。
    -- 必须先快照所有旧目标再逐个取消：把整个子列表传给 cancelTarget 会
    -- 对同一张表边遍历边删除，Lua 的 ipairs 会跳过一半目标导致漏取消。
    local oldTos = {}
    for _, group in ipairs(use.tos) do
      if type(group) == "table" and group[1] and group[1].class then
        for _, t in ipairs(group) do table.insert(oldTos, t) end
      end
    end
    for _, t in ipairs(oldTos) do
      use:cancelTarget(t)
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
    -- 补齐新使用者的“使用者身份”：
    -- 1) 使用次数记录转移（extraUse 的牌在 useCard 开头本就不记账）。
    -- 2) 重触发 fk.CardUsing：该事件的触发对象就是 useCardData.from，
    --    因此只有 target==player 的技能命中，即新使用者的使用者侧技能
    --    （含装备区挂在 CardUsing 上的技能）获得触发机会；
    --    旧使用者此前已触发过的技能不会重复。之后的 TargetSpecified/
    --    CardEffecting/Damage 等事件引擎自动携带新使用者，无需手动处理。
    if not useData.extraUse then
      oldUser:addCardUseHistory(use.card.trueName, -1)
      newUser:addCardUseHistory(use.card.trueName, 1)
    end
    if newUser:isAlive() then
      room.logic:trigger(fk.CardUsing, newUser, useData)
    end
  end,
})

return zonghuan
