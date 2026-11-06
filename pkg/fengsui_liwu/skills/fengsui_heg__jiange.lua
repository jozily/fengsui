local CardNameUI = require "packages.fengsui.pkg.card_name_ui"
local s = fk.CreateSkill { name = "fengsui_heg__jiange" }
s.bypass_distances = function(self, player, card)
  return card and card.skillName == s.name
end

local options = { "slash", "duel" }

-- 每轮每项限一次：-round 后缀标记每轮自动清除
local function optionMark(name)
  return s.name .. "_" .. name .. "-round"
end

local function optionAvailable(player, name)
  return player:getMark(optionMark(name)) == 0
end

local function availableOptions(player)
  return table.filter(options, function(n)
    return optionAvailable(player, n)
  end)
end

-- 响应请求（求杀、决斗的打出杀等）时按 pattern 自动匹配，出牌阶段则由玩家自选
local function responseName()
  local pattern = Fk.currentResponsePattern
  if not pattern then return end
  local exp = Exppattern:Parse(pattern)
  for _, name in ipairs(options) do
    if exp:match(Fk:cloneCard(name)) then return name end
  end
end

local function isMaterial(to_select)
  local c = Fk:getCardById(to_select)
  return c.type == Card.TypeTrick or c.type == Card.TypeEquip
end

local function hasMaterial(player)
  return table.find(player:getCardIds("h"), isMaterial) ~= nil
end

s:addEffect("viewas", {
  pattern = "slash,duel",
  handly_pile = true,
  prompt = "#fengsui_heg__jiange-invoke",
  interaction = function(self, player)
    if responseName() then return end
    local choices = availableOptions(player)
    if #choices == 0 then return end
    return CardNameUI.create(s.name, choices, options)
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    return isMaterial(to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local name = responseName()
    if not name then
      local data = self.interaction and self.interaction.data
      if data and table.contains(options, data) and optionAvailable(player, data) then
        name = data
      else
        -- 兜底：interaction.data 缺失或残留了已用完的选项时，
        -- 若只剩一项可用则自动选定，避免玩家二次点击
        local left = availableOptions(player)
        if #left == 1 then name = left[1] end
      end
    end
    if not name or not optionAvailable(player, name) then return end
    local c = Fk:cloneCard(name)
    c.skillName = s.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return #availableOptions(player) > 0 and hasMaterial(player)
  end,
  enabled_at_response = function(self, player, response)
    local name = responseName()
    return name ~= nil and optionAvailable(player, name) and hasMaterial(player)
  end,
  -- 用牌之后直接摸牌、记录限次：after_use 会被引擎编译成 afterUse（使用路径）
  -- 与 afterResponse（打出路径），两张路径都在 viewas 自身流程内回调，
  -- 不额外触发任何技能、不弹发动提示。
  after_use = function(self, user, data)
    local card = data and data.card
    if not card or not table.contains(options, card.name) or
      not table.contains(card.skillNames or {}, s.name) then return end
    local room = user.room
    room:setPlayerMark(user, optionMark(card.name), 1)
    if not user.dead then
      user:drawCards(1, s.name)
    end
  end,
})

return s
