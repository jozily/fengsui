local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local CardNameUI = require "packages.fengsui.pkg.card_name_ui"

local fuhui = fk.CreateSkill{
  name = "fengsui_heg__fuhui",
}

local function allNames(player)
  local names = U.getNationalCardNames({"basic", "trick"})
  if Fk.all_card_types["threaten_emperor"] then
    table.insertIfNeed(names, "threaten_emperor")
  end
  return player:getViewAsCardNames(fuhui.name, names)
end

fuhui:addEffect("viewas", {
  anim_type = "support",
  prompt = "#fengsui_heg__fuhui-invoke",
  interaction = function(self, player)
    local names = allNames(player)
    return CardNameUI.create(fuhui.name, names, names)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 or not self.interaction.data then return end
    local first, second = Fk:getCardById(cards[1]), Fk:getCardById(cards[2])
    local difference = math.abs(first.number - second.number)
    if utf8.len(Fk:translate(self.interaction.data)) ~= difference then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = fuhui.name
    card:addSubcards(cards)
    return card
  end,
  before_use = function(self, player, use)
    U.hideSkillGeneral(player, fuhui.name)
  end,
  enabled_at_play = function(self, player)
    return player:hasSkill(fuhui.name) and H.allGeneralsRevealed(player) and
      #player:getCardIds("he") >= 2
  end,
  enabled_at_response = function(self, player, response)
    return player:hasSkill(fuhui.name) and H.allGeneralsRevealed(player) and
      #player:getCardIds("he") >= 2
  end,
})

return fuhui
