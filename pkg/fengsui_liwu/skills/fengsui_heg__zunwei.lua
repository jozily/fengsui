local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local zunwei = fk.CreateSkill {
  name = "fengsui_heg__zunwei",
}

-- 可转化的牌名：当前牌池里所有实体基本牌与普通锦囊牌，
-- 【杀】【闪】【桃】【无懈可击】等都在其中。
local function allCardNames()
  local names = U.getNationalCardNames({ "basic", "trick" })
  -- 四种常见响应牌名始终保留，避免牌池裁剪后响应【杀】【闪】【桃】【无懈】时选不出牌。
  for _, name in ipairs({ "jink", "nullification", "peach", "slash" }) do
    table.insertIfNeed(names, name)
  end
  return names
end

-- 响应请求下按请求 pattern 预选牌名。客户端有时带不上
-- Fk.currentResponsePattern（见 fengsui_heg__jiange），此时选项框照常给出全部牌名，
-- 由 CardNameBox 的 default 写进 interaction.data，玩家也可自行改选。
local responseOrder = { "jink", "nullification", "peach", "slash" }
local function responseName(names)
  local pattern = Fk.currentResponsePattern
  if not pattern or pattern == "" then return end
  local ok, exp = pcall(Exppattern.Parse, Exppattern, pattern)
  if not ok or not exp then return end
  for _, name in ipairs(responseOrder) do
    if table.contains(names, name) and exp:match(Fk:cloneCard(name)) then return name end
  end
  for _, name in ipairs(names) do
    if exp:match(Fk:cloneCard(name)) then return name end
  end
end

zunwei:addEffect("viewas", {
  anim_type = "support",
  -- 武圣式的一体按钮：单个 viewas 同时覆盖「使用」与「打出/响应」。
  -- pattern = "." 让按钮在 ReqUseCard、ReqResponseCard 与无懈请求下都可用，
  -- 不再拆出第二个「尊位」技能、响应时也不会出现两个同名按钮。
  pattern = ".",
  prompt = "#fengsui_heg__zunwei-invoke",
  interaction = function(self, player)
    local names = allCardNames()
    if #names == 0 then return end
    -- 选项框必须始终存在：interaction.data 由 default 兜底，view_as 靠它确定牌名；
    -- 返回 nil 会表现为点了技能按钮却造不出牌。
    return CardNameUI.create(zunwei.name, names, names, responseName(names) or names[1])
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {},
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local name = self.interaction and self.interaction.data
    if not name then return end
    local card = Fk:cloneCard(name)
    card.skillName = zunwei.name
    return card
  end,
  before_use = function(self, player, use)
    H.removeGeneral(player, true, zunwei.name)
  end,
  -- after_use 被引擎编译成 afterUse（使用路径）与 afterResponse（打出路径），
  -- 两条路径都在 viewas 自身流程内回调，不额外触发技能、不弹发动提示。
  after_use = function(self, player, use)
    if player.dead then return end
    local room = player.room
    room:throwCard(player:getCardIds("h"), zunwei.name, player, player)
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then player:drawCards(n, zunwei.name) end
  end,
  enabled_at_play = function(self, player)
    return player.phase == Player.Play and H.hasGeneral(player, true)
  end,
  enabled_at_response = function(self, player, response)
    return H.hasGeneral(player, true)
  end,
  enabled_at_nullification = function(self, player)
    return H.hasGeneral(player, true)
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__zunwei-invoke"] = "尊位：移除副将，视为使用或打出一张基本牌或普通锦囊牌，然后弃置所有手牌并将手牌数摸至体力上限",
}

return zunwei
