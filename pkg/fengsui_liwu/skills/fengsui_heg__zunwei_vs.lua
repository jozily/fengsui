-- 【已废弃，勿再挂载】
-- 2026-11-12 起，尊位的「使用」与「打出/响应」合并进
-- fengsui_heg__zunwei.lua 的单个 viewas 一体按钮（武圣式写法）。
-- 本文件保留旧响应实现仅作历史参考，未注册到任何武将；
-- 若重新 addSkills 挂载，响应时会再次出现两个「尊位」按钮。

local H = require "packages.fengsui.hegemony_util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local zunweiVs = fk.CreateSkill {
  name = "fengsui_heg__zunwei_vs",
}

local options = { "jink", "nullification" }

-- 客户端在部分「使用牌」请求里不一定带得上 Fk.currentResponsePattern
-- （参见 fengsui_heg__jiange），故转化牌名不能只依赖它：
-- 选项框始终存在，并把默认牌名写进 interaction.data 供 view_as 兜底。
local function responseName()
  local pattern = Fk.currentResponsePattern
  if not pattern or pattern == "" then return end
  local ok, exp = pcall(Exppattern.Parse, Exppattern, pattern)
  if not ok or not exp then return end
  for _, name in ipairs(options) do
    if exp:match(Fk:cloneCard(name)) then return name end
  end
end

zunweiVs:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "jink,nullification",
  prompt = "#fengsui_heg__zunwei-response",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {},
  },
  card_filter = function() return false end,
  interaction = function(self, player)
    return CardNameUI.create(zunweiVs.name, options, options, responseName() or "jink")
  end,
  view_as = function(self, player, cards)
    local name = responseName()
    if not name and self.interaction and self.interaction.data then
      name = self.interaction.data
    end
    if not table.contains(options, name) then name = "jink" end
    local card = Fk:cloneCard(name)
    card.skillName = zunweiVs.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    H.removeGeneral(player, true, zunweiVs.name)
    if player.dead then return end
    room:throwCard(player:getCardIds("h"), zunweiVs.name, player, player)
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then player:drawCards(n, zunweiVs.name) end
  end,
  enabled_at_play = function() return false end,
  -- 按钮是否相容由引擎按 skill.pattern 把关，这里只判断技能本身能否发动
  enabled_at_response = function(self, player)
    return H.hasGeneral(player, true)
  end,
  enabled_at_nullification = function(self, player)
    return H.hasGeneral(player, true)
  end,
})

Fk:loadTranslationTable {
  ["fengsui_heg__zunwei_vs"] = "尊位",
  [":fengsui_heg__zunwei_vs"] = "当你需要使用或打出【闪】或【无懈可击】时，你可以移除副将视为使用或打出之，然后弃置所有手牌并将手牌数摸至体力上限。",
  ["#fengsui_heg__zunwei-response"] = "尊位：移除副将并视为使用【闪】或【无懈可击】响应，然后弃置所有手牌并将手牌数摸至体力上限",
}

return zunweiVs
