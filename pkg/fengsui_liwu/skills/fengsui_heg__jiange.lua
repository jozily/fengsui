local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local s = fk.CreateSkill { name = "fengsui_heg__jiange" }
s.bypass_distances = function(self, player, card)
  return card and card.skillName == s.name
end

-- 响应请求（求杀等）时按 pattern 自动匹配，出牌阶段则由玩家自选
local function responseName()
  local pattern = Fk.currentResponsePattern
  if not pattern then return end
  local exp = Exppattern:Parse(pattern)
  if exp:match(Fk:cloneCard("slash")) then return "slash" end
  if exp:match(Fk:cloneCard("duel")) then return "duel" end
end

-- 每轮每项限一次：-round 后缀标记每轮自动清除
local function optionMark(name)
  return s.name .. "_" .. name .. "-round"
end

local function optionAvailable(player, name)
  return player:getMark(optionMark(name)) == 0
end

s:addEffect("viewas", {
  pattern = "slash,duel",
  handly_pile = true,
  can_use = function(self, player)
    return table.find({ "slash", "duel" }, function(n)
      return optionAvailable(player, n)
    end)
  end,
  interaction = function(self, player)
    if responseName() then return end
    local choices = table.filter({ "slash", "duel" }, function(n)
      return optionAvailable(player, n)
    end)
    if #choices == 0 then return end
    return CardNameUI.create(s.name, choices, { "slash", "duel" })
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local c = Fk:getCardById(to_select)
    return c.type == Card.TypeTrick or c.type == Card.TypeEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local name = responseName()
    if not name and self.interaction and self.interaction.data then
      name = self.interaction.data
    end
    if not name or not optionAvailable(player, name) then return end
    local c = Fk:cloneCard(name)
    c.skillName = s.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    player:drawCards(1, s.name)
  end,
})

-- 记录本轮已使用的选项（使用与打出均计入）
local function recordSpec(event)
  return {
    frequency = Skill.Compulsory,
    can_trigger = function(self, _, target, player, data)
      return target == player and data.card and data.card.skillName == s.name and
        (data.card.name == "slash" or data.card.name == "duel")
    end,
    on_use = function(self, _, target, player, data)
      player.room:setPlayerMark(player, optionMark(data.card.name), 1)
    end,
  }
end

s:addEffect(fk.CardUsing, recordSpec(fk.CardUsing))
s:addEffect(fk.CardResponding, recordSpec(fk.CardResponding))

return s
