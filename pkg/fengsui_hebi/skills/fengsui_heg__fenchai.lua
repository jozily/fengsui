local H = require "packages.fengsui.hegemony_util"

local fenchai = fk.CreateSkill{
  name = "fengsui_heg__fenchai",
}

fenchai:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fengsui_heg__fenchai-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(fenchai.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected ~= 0 or to_select == player or player.gender == to_select.gender or
      player.gender == General.GenderUnknown or to_select.gender == General.GenderUnknown then
      return false
    end
    local slash = Fk:cloneCard("ice__slash")
    slash.skillName = fenchai.name
    return player:canUseTo(slash, to_select, { bypass_times = true, bypass_distances = true }) and
      to_select:canUseTo(slash, player, { bypass_times = true, bypass_distances = true })
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    room:useVirtualCard("ice__slash", nil, player, target, fenchai.name, true)
    if player:isAlive() and target:isAlive() then
      room:useVirtualCard("ice__slash", nil, target, player, fenchai.name, true)
    end
  end,
})

fenchai:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fenchai.name) and data.card.name == "ice__slash" and
      table.contains(data.card.skillNames, fenchai.name) and
      (data.from == player or table.contains(data.tos, player))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local damaged = table.filter(data.tos, function(p)
      return data.damageDealt and data.damageDealt[p] and data.damageDealt[p] > 0
    end)
    if #damaged > 0 then
      for _, p in ipairs(damaged) do
        if p:isAlive() and room:askToSkillInvoke(player, {
          skill_name = fenchai.name,
          prompt = "#fengsui_heg__fenchai-change::" .. p.id,
        }) then
          H.askToHebiOrTransform(room, p, fenchai.name, false)
        end
      end
      return
    end

    local participants = {data.from}
    for _, p in ipairs(data.tos) do
      table.insertIfNeed(participants, p)
    end
    if not table.find(participants, function(p)
      return p and p:isAlive() and p:getMark("@!!yinyangfish") == 0
    end) then
      return
    end

    if room:askToSkillInvoke(player, {
      skill_name = fenchai.name,
      prompt = "#fengsui_heg__fenchai-fish",
    }) then
      if data.from and data.from:isAlive() and data.from:getMark("@!!yinyangfish") == 0 then
        H.addHegMark(data.from, "yinyangfish")
      end
      for _, p in ipairs(data.tos) do
        if p:isAlive() and p ~= data.from and p:getMark("@!!yinyangfish") == 0 then
          H.addHegMark(p, "yinyangfish")
        end
      end
    end
  end,
})

return fenchai
