local H = require "packages.fengsui.hegemony_util"

local fuyin = fk.CreateSkill{
  name = "fengsui_heg__fuyin",
}

fuyin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuyin.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function(p)
        return p ~= player and H.compareKingdomWith(p, player) and not p:isNude()
      end) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player) and not p:isNude()
    end)
    local tops, bottoms = {}, {}
    for _, p in ipairs(targets) do
      local choices = {"fuyin_top", "fuyin_bottom", "Cancel"}
      local choice = room:askToChoice(p, { choices = choices, skill_name = fuyin.name })
      if choice ~= "Cancel" then
         local card = room:askToChooseCard(p, {
           target = p,
           flag = "he",
           skill_name = fuyin.name,
         })
         local pos = choice == "fuyin_top" and 1 or -1
         room:moveCards({
           ids = {card},
           toArea = Card.DrawPile,
           drawPilePosition = pos,
           moveReason = fk.ReasonPut,
           skillName = fuyin.name,
           proposer = p,
           moveVisible = true,
         })
         if choice == "fuyin_top" then table.insert(tops, p.id)
           room:setPlayerMark(p, "@fengsui_heg__fuyin_top-turn", player.id)
         else
           table.insert(bottoms, p.id)
           room:setPlayerMark(p, "@fengsui_heg__fuyin_bottom-turn", player.id)
         end
      end
    end
    if #tops + #bottoms > 0 then
      room:setPlayerMark(player, "fengsui_heg__fuyin_tops-turn", tops)
      room:setPlayerMark(player, "fengsui_heg__fuyin_bottoms-turn", bottoms)
      room:setPlayerMark(player, "fengsui_heg__fuyin_damage-turn", 0)
      room:setPlayerMark(player, "fengsui_heg__fuyin_discard-turn", 0)
    end
  end,
})

-- 记录本回合伤害
fuyin:addEffect(fk.Damage, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return type(player:getMark("fengsui_heg__fuyin_tops-turn")) == "table" and data.from == player
  end,
  on_use = function(self, event, target, player, data)
    local dmg = player:getMark("fengsui_heg__fuyin_damage-turn") + data.damage
    player.room:setPlayerMark(player, "fengsui_heg__fuyin_damage-turn", dmg)
  end,
})

-- 记录本回合弃置
fuyin:addEffect(fk.AfterCardsMove, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if type(player:getMark("fengsui_heg__fuyin_tops-turn")) ~= "table" then return false end
    for _, move in ipairs(data) do
       if move.from == player and move.moveReason == fk.ReasonDiscard then return true end
    end
  end,
  on_use = function(self, event, target, player, data)
    local sum = player:getMark("fengsui_heg__fuyin_discard-turn")
    for _, move in ipairs(data) do
       if move.from == player and move.moveReason == fk.ReasonDiscard then
           sum = sum + #move.moveInfo
       end
    end
    player.room:setPlayerMark(player, "fengsui_heg__fuyin_discard-turn", sum)
  end,
})

-- 回合结束结算
fuyin:addEffect(fk.EventPhaseStart, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and
      type(player:getMark("fengsui_heg__fuyin_tops-turn")) == "table"
  end,
  on_use = function(self, event, target, player, data)
     local dmg = player:getMark("fengsui_heg__fuyin_damage-turn")
     local dis = player:getMark("fengsui_heg__fuyin_discard-turn")
     local tops = player:getTableMark("fengsui_heg__fuyin_tops-turn")
     local bottoms = player:getTableMark("fengsui_heg__fuyin_bottoms-turn")
     local room = player.room

     local draws, loses = {}, {}
     if dmg > dis then
         draws, loses = tops, bottoms
     elseif dmg < dis then
         draws, loses = bottoms, tops
     end

     for _, pid in ipairs(draws) do
        local p = room:getPlayerById(pid)
        if p and p:isAlive() then p:drawCards(2, fuyin.name) end
     end
     for _, pid in ipairs(loses) do
        local p = room:getPlayerById(pid)
        if p and p:isAlive() then room:loseHp(p, 1, fuyin.name) end
     end

     room:setPlayerMark(player, "fengsui_heg__fuyin_tops-turn", 0)
     room:setPlayerMark(player, "fengsui_heg__fuyin_bottoms-turn", 0)
     room:setPlayerMark(player, "fengsui_heg__fuyin_damage-turn", 0)
     room:setPlayerMark(player, "fengsui_heg__fuyin_discard-turn", 0)
     for _, pid in ipairs(table.connect(tops, bottoms)) do
       local p = room:getPlayerById(pid)
       if p then
         room:setPlayerMark(p, "@fengsui_heg__fuyin_top-turn", 0)
         room:setPlayerMark(p, "@fengsui_heg__fuyin_bottom-turn", 0)
       end
     end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__fuyin"] = "负胤",
  [":fengsui_heg__fuyin"] = "准备阶段，所有其他同势力角色可选择用一张牌替换牌堆顶/底的牌。回合结束时，若你于本回合造成的伤害数大于/小于弃置的牌数，所有选择牌堆顶/牌堆底的角色摸两张牌，选择另一项的角色失去一点体力。",
  ["fuyin_top"] = "替换牌堆顶",
  ["fuyin_bottom"] = "替换牌堆底",
  ["@fengsui_heg__fuyin_top-turn"] = "负胤：",
  ["@fengsui_heg__fuyin_bottom-turn"] = "负胤：",
}

return fuyin
