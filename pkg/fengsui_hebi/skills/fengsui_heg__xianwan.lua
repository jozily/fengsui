local H = require "packages.hegemony.util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local xianwan = fk.CreateSkill{
  name = "fengsui_heg__xianwan",
}

local function availableNames(player)
  return player:getViewAsCardNames(xianwan.name, { "slash", "jink" })
end

xianwan:addEffect("viewas", {
  anim_type = "defensive",
  pattern = "slash,jink",
  prompt = "#fengsui_heg__xianwan",
  interaction = function(self, player)
    local names = availableNames(player)
    if #names == 0 then return end
    return UI.CardNameBox {
      choices = names,
      all_choices = { "slash", "jink" },
    }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if #cards ~= 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = xianwan.name
    return card
  end,
  before_use = function(self, player, use)
    U.hideSkillGeneral(player, xianwan.name)
  end,
  enabled_at_play = function(self, player)
    return player:hasSkill(xianwan.name) and H.allGeneralsRevealed(player) and
      #availableNames(player) > 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:hasSkill(xianwan.name) and
      H.allGeneralsRevealed(player) and #availableNames(player) > 0
  end,
})

return xianwan
