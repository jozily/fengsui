local H = require "packages.hegemony.util"

local baizu = fk.CreateSkill{
  name = "fengsui_heg__baizu",
  tags = {Skill.Compulsory},
}

baizu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baizu.name) and player.phase == Player.Finish and
           player:isWounded() and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    
    -- 1. 抓取场上所有其他存在的势力
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        local kd = H.getKingdom(p)
        if not table.contains(kingdoms, kd) then
          table.insert(kingdoms, kd)
        end
      end
    end
    
    -- 2. 强制令玩家在每一个势力中挑选一名角色
    local chosen_targets = {}
    for _, kd in ipairs(kingdoms) do
      local p_in_kd = table.filter(room.alive_players, function(p)
        return p ~= player and H.getKingdom(p) == kd
      end)
      if #p_in_kd > 0 then
        local display_kd = Fk:translate(kd)
        local to = room:askToChoosePlayers(player, {
          targets = p_in_kd,
          min_num = 1, max_num = 1,
          prompt = "#fengsui_heg__baizu-choose::" .. display_kd,
          skill_name = baizu.name,
          cancelable = false,
        })
        if #to > 0 then
          table.insert(chosen_targets, to[1])
        end
      end
    end
    
    -- 3. 将技能主本人一并加入弃牌序列
    table.insert(chosen_targets, player)
    
    -- 4. 按顺序执行弃牌操作，并记录每一个弃用牌的分类
    local discards = {}
    for _, t in ipairs(chosen_targets) do
      -- Freekill中 not isNude 即可囊括 装备区 与 手牌区
      if t:isAlive() and not t:isNude() then
        local t_card = room:askToDiscard(t, {
          min_num = 1, max_num = 1,
          include_equip = true,
          prompt = "#fengsui_heg__baizu-discard",
          skill_name = baizu.name,
          cancelable = false,
        })
        if #t_card > 0 then
          local ctype = Fk:getCardById(t_card[1]).type
          discards[t.id] = ctype
        end
      end
    end
    
    -- 5. 统计种类被命中的次数
    local type_count = {}
    for pid, ctype in pairs(discards) do
      type_count[ctype] = (type_count[ctype] or 0) + 1
    end
    
    -- 6. 对记录在多选类别上的所有相关倒霉蛋发送惩罚
    local to_lose_hp = {}
    for pid, ctype in pairs(discards) do
      if type_count[ctype] > 1 then
        local t = room:getPlayerById(pid)
        -- 为后续结算奖励，提前记录其受伤前的国籍身份
        table.insert(to_lose_hp, { target = t, k = H.getKingdom(t) })
      end
    end
    
    -- 7. 结算扣血及死亡奖励机制
    local dead_info = {}
    for _, info in ipairs(to_lose_hp) do
      local t = info.target
      if t and t:isAlive() then
        room:loseHp(t, 1, baizu.name)
        if t.dead then
          table.insert(dead_info, info.k)
        end
      end
    end
    
    -- 8. 奖励收尾 (死亡后清算)
    for _, dk in ipairs(dead_info) do
      if dk == H.getKingdom(player) then
        local deputy = player.deputyGeneral == "anjiang" and player:getMark("__heg_deputy") or player.deputyGeneral
        if deputy and deputy ~= "" then
      H.removeGeneral(player, true)
        end
      else
        local kingdom_num = table.count(room.alive_players, function(p)
          return H.getKingdom(p) == dk
        end)
        if kingdom_num > 0 then
          player:drawCards(kingdom_num, baizu.name)
        end
      end
    end
    
  end,
})

return baizu
