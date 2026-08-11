local H = require "packages.fengsui.hegemony_util"

local qujian = fk.CreateSkill{
  name = "fengsui_heg__qujian",
}

qujian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qujian.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local same_count = #table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
    end)

    local chosen = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1, max_num = same_count,
      prompt = "#fengsui_heg__qujian-choose:::" .. same_count,
      skill_name = qujian.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, { targets = chosen })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).targets

    for _, p in ipairs(targets) do
      if p:isAlive() then p:drawCards(1, qujian.name) end
    end

    local min_val = 99
    local max_val = -1
    local min_ps = {}
    local max_ps = {}

    for _, p in ipairs(targets) do
      if p:isAlive() then
        local hc = p:getHandcardNum()
        if hc < min_val then
          min_val = hc
          min_ps = { p }
        elseif hc == min_val then
          table.insert(min_ps, p)
        end

        if hc > max_val then
          max_val = hc
          max_ps = { p }
        elseif hc == max_val then
          table.insert(max_ps, p)
        end
      end
    end

    if #min_ps == 1 and #max_ps == 1 and min_ps[1] ~= max_ps[1] then
      local from_p = min_ps[1]
      local to_p = max_ps[1]

      room:useVirtualCard("thunder__slash", nil, from_p, to_p, qujian.name, true)
    end

    local pin_targets = table.filter(targets, function(p)
      return p:isAlive() and not p:isKongcheng() and not player:isKongcheng() and p ~= player
    end)

    if #pin_targets > 0 then
      local pin_to = room:askToChoosePlayers(player, {
        targets = pin_targets,
        min_num = 1, max_num = 1,
        prompt = "#fengsui_heg__qujian-pindian",
        skill_name = qujian.name,
        cancelable = true,
      })
      if #pin_to > 0 then
        local target_p = pin_to[1]
        local pd = player:pindian({ target_p }, qujian.name)
        local result = pd.results[target_p]
        local win = result and result.winner
        if win == player then
          target_p:setChainState(true)
        elseif win == target_p then
          player:setChainState(true)
        end
      end
    end
  end,
})

return qujian
