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

-- 只用来给「响应请求」（求杀、决斗打出杀等）预选牌名。
-- 客户端不一定带得上 Fk.currentResponsePattern，故不能把转化的牌名完全寄托于此。
local function responseName()
  local pattern = Fk.currentResponsePattern
  if not pattern or pattern == "" then return end
  local ok, exp = pcall(Exppattern.Parse, Exppattern, pattern)
  if not ok or not exp then return end
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
    local choices = availableOptions(player)
    if #choices == 0 then return end
    -- 选项框必须始终存在：引擎会把 interaction.default 写进 interaction.data，
    -- view_as 靠它确定牌名。返回 nil 会让 interaction.data 一直为空，
    -- 在「使用牌」请求（侠望等）里表现为点了技能按钮却选不出牌。
    local default = responseName()
    if default and not table.contains(choices, default) then default = nil end
    return CardNameUI.create(s.name, choices, options, default)
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    return isMaterial(to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    -- 玩家在选项框里选的牌名优先；响应请求下该值就是自动预选的牌名。
    local name = self.interaction and self.interaction.data
    if not table.contains(options, name) or not optionAvailable(player, name) then
      name = responseName()
    end
    if not name or not optionAvailable(player, name) then
      -- 兜底：interaction.data 缺失或残留已用完的选项时，
      -- 只剩一项可用则自动选定，避免玩家二次点击
      local left = availableOptions(player)
      if #left == 1 then name = left[1] end
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
    -- 使用牌请求（ReqUseCard）与响应请求都会走到这里，但客户端未必带得上
    -- currentResponsePattern；按钮是否相容由引擎的 matchExp(skill.pattern) 把关，
    -- 这里只判断技能本身还能不能发动。
    if #availableOptions(player) == 0 or not hasMaterial(player) then return false end
    if response == true then
      local name = responseName()
      -- 拿得到请求牌名时才按它校验（例如求杀却只剩决斗次数），
      -- 拿不到则放行，避免客户端缺 pattern 时按钮整个消失。
      if name then return optionAvailable(player, name) end
    end
    return true
  end,
  -- 用牌之后直接摸牌、记录限次：after_use 会被引擎编译成 afterUse（使用路径）
  -- 与 afterResponse（打出路径），两条路径都在 viewas 自身流程内回调，
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
