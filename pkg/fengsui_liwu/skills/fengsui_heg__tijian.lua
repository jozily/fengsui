local H = require "packages.fengsui.hegemony_util"

local tijian = fk.CreateSkill {
  name = "fengsui_heg__tijian",
}

local USE_COUNT = "fengsui_heg__tijian_use-turn"

-- 统计每名角色本回合使用的牌数（每张牌结算后 +1，-turn 回合结束自动清零）。
-- global 效果对每个玩家遍历，用 player == target 保证一张牌只计一次。
tijian:addEffect(fk.CardUseFinished, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return player == target and target ~= nil and data.card ~= nil
  end,
  on_refresh = function(self, event, target, player, data)
    local room = target.room
    room:setPlayerMark(target, USE_COUNT, (target:getMark(USE_COUNT) or 0) + 1)
  end,
})

tijian:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tijian.name) then return false end
    if not data or not data.use or not data.card or data.cancelled then return false end
    if not data.firstTarget then return false end
    if #(data.use.tos or {}) == 0 then return false end
    -- target 是此牌使用者；须与钟毓势力相同，且在其自己的回合内
    if not target or not target:isAlive() then return false end
    if not H.compareKingdomWith(player, target) then return false end
    if target.room.current ~= target then return false end
    local x = data.card:getNameLength()
    if x < 1 then return false end
    -- 本牌是使用者本回合使用的第 x 张牌
    if (target:getMark(USE_COUNT) or 0) + 1 ~= x then return false end
    return table.find(data.use.tos, function(p) return p and p:isAlive() end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = tijian.name,
      prompt = "#fengsui_heg__tijian-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = data.card:getNameLength()
    local tos = table.filter(data.use.tos, function(p) return p and p:isAlive() end)
    if #tos == 0 then return end
    local chosen = tos
    if #tos > 1 then
      chosen = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        skill_name = tijian.name,
        prompt = "#fengsui_heg__tijian-target",
        cancelable = false,
      })
    end
    if not chosen or #chosen == 0 then return end
    local to = chosen[1]
    local n = math.min(x, #to:getCardIds("he"))
    if n > 0 then
      room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = tijian.name,
        cancelable = false,
      })
    end
    to:drawCards(x, tijian.name)
  end,
})

return tijian
