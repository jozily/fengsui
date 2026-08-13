local H = require "packages.fengsui.hegemony_util"

local chenmeng = fk.CreateSkill{
  name = "fengsui_heg__chenmengRemake",
}

local function revealedKingdomGenerals(room, player)
  local n = 0
  for _, p in ipairs(room.alive_players) do
    if H.compareKingdomWith(p, player) then n = n + H.getGeneralsRevealedNum(p) end
  end
  return n
end

local function canDiscard(player)
  return #player:getCardIds("he") >= 2
end

local function canExchange(player)
  return player:getMark("@!!vanguard") + player:getMark("@!!yinyangfish") +
    player:getMark("@!!companion") + player:getMark("@!!wild") > 0 and not player:isKongcheng()
end

local function doOption(room, player, option)
  if option == "fengsui_heg__chenmengRemake_discard" then
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = #player:getCardIds("he"),
      include_equip = true,
      skill_name = chenmeng.name,
      prompt = "#fengsui_heg__chenmengRemake-discard",
      cancelable = false,
    })
    if #cards < 2 then return end
    if #cards == revealedKingdomGenerals(room, player) then
      H.addHegMark(player, "companion")
    else
      H.addHegMark(player, "yinyangfish")
    end
  elseif canExchange(player) then
    local names = {"@!!vanguard", "@!!yinyangfish", "@!!companion", "@!!wild"}
    names = table.filter(names, function(name) return player:getMark(name) > 0 end)
    local mark = room:askToChoice(player, {
      choices = names,
      skill_name = chenmeng.name,
      prompt = "#fengsui_heg__chenmengRemake-mark",
    })
    local id = room:askToChooseCard(player, {
      target = player,
      flag = "he",
      skill_name = chenmeng.name,
      prompt = "#fengsui_heg__chenmengRemake-exchange",
    })
    if id then
      local mark_type = ({["@!!vanguard"]="vanguard", ["@!!yinyangfish"]="yinyangfish", ["@!!companion"]="companion", ["@!!wild"]="wild"})[mark]
      H.removeHegMark(room, player, mark_type, 1)
      room:moveCards{ids = {id}, from = player, toArea = Card.DrawPile,
        moveReason = fk.ReasonPut, skillName = chenmeng.name, drawPilePosition = 1}
    end
  end
end

chenmeng:addEffect("active", {
  global = true,
  anim_type = "support",
  prompt = "#fengsui_heg__chenmengRemake",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    local room = player.room or Fk:currentRoom()
    if not room then return false end
    local owner = table.find(room.alive_players, function(p)
      return p:hasSkill(chenmeng.name) and H.inFormationRelation(p, player)
    end)
    return owner ~= nil and player:usedSkillTimes(chenmeng.name, Player.HistoryPhase) == 0 and
      (canDiscard(player) or canExchange(player))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choices = {}
    if canDiscard(player) then table.insert(choices, "fengsui_heg__chenmengRemake_discard") end
    if canExchange(player) then table.insert(choices, "fengsui_heg__chenmengRemake_exchange") end
    local choice = room:askToChoice(player, {choices = choices, skill_name = chenmeng.name,
      prompt = "#fengsui_heg__chenmengRemake-choice"})
    doOption(room, player, choice)
    local other = choice == "fengsui_heg__chenmengRemake_discard" and
      "fengsui_heg__chenmengRemake_exchange" or "fengsui_heg__chenmengRemake_discard"
    room:setPlayerMark(player, "fengsui_heg__chenmengRemake_pending-turn", other)
  end,
})

chenmeng:addEffect(fk.TurnEnd, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__chenmengRemake_pending-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local option = player:getMark("fengsui_heg__chenmengRemake_pending-turn")
    room:setPlayerMark(player, "fengsui_heg__chenmengRemake_pending-turn", 0)
    doOption(room, player, option)
  end,
})

return chenmeng
