local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local zunwei = fk.CreateSkill {
  name = "fengsui_heg__zunwei",
}

local function responseName()
  local pattern = Fk.currentResponsePattern
  if not pattern then return end
  local exp = Exppattern:Parse(pattern)
  if exp:match(Fk:cloneCard("jink")) then return "jink" end
  if exp:match(Fk:cloneCard("nullification")) then return "nullification" end
end

zunwei:addEffect("viewas", {
  anim_type = "support",
  pattern = ".",
  prompt = "#fengsui_heg__zunwei-invoke",
  interaction = function(self, player)
    if responseName() then return end
    local names = U.getNationalCardNames({ "basic", "trick" })
    return CardNameUI.create(zunwei.name, names, names)
  end,
  card_filter = function() return false end,
  view_as = function(self, player, cards)
    local name = responseName()
    if not name and self.interaction and self.interaction.data then
      name = self.interaction.data
    end
    if not name then return end
    local card = Fk:cloneCard(name)
    card.skillName = zunwei.name
    return card
  end,
  before_use = function(self, player, use)
    H.removeGeneral(player, true, zunwei.name)
    if player.dead then return end
  end,
  after_use = function(self, player, use)
    local room = player.room
    if player.dead then return end
    room:throwCard(player:getCardIds("h"), zunwei.name, player, player)
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then player:drawCards(n, zunwei.name) end
  end,
  enabled_at_play = function(self, player)
    return player.phase == Player.Play and H.hasGeneral(player, true)
  end,
  enabled_at_response = function(self, player)
    return H.hasGeneral(player, true) and responseName() ~= nil
  end,
  enabled_at_nullification = function(self, player)
    return H.hasGeneral(player, true) and responseName() == "nullification"
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__zunwei-invoke"] = "尊位：移除副将并视为使用一张基本牌或普通锦囊牌",
}

return zunwei
