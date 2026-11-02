local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local fuzhu = fk.CreateSkill{
  name = "fengsui_heg__fuzhu",
}

local top_choice = "fengsui_heg__fuzhu_top"
local bottom_choice = "fengsui_heg__fuzhu_bottom"

fuzhu:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuzhu.name) and data.card and
      data.card.is_damage_card and H.allGeneralsRevealed(player) and
      #player.room.draw_pile > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local place = room:askToChoice(player, {
      choices = { top_choice, bottom_choice },
      skill_name = fuzhu.name,
      prompt = "#fengsui_heg__fuzhu-invoke",
      cancelable = true,
    })
    if place and place ~= "Cancel" then
      event:setCostData(self, { from_top = place == top_choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from_top = event:getCostData(self).from_top
    U.hideSkillGeneral(player, fuzhu.name)
    if player.dead then return end

    local ids = room:getNCards(1, from_top and "top" or "bottom")
    if #ids == 0 then return end
    room:showCards(ids, player)
    if player.dead then return end

    local id = ids[1]
    if room:getCardArea(id) ~= Card.DrawPile then return end
    local card = Fk:getCardById(id)
    if not card or player:prohibitUse(card) or not player:canUse(card) then return end

    local use = room:askToUseRealCard(player, {
      pattern = tostring(Exppattern{ id = { id } }),
      skill_name = fuzhu.name,
      prompt = "#fengsui_heg__fuzhu-use",
      cancelable = true,
      skip = true,
      expand_pile = { id },
    })
    if use then room:useCard(use) end
  end,
})

return fuzhu
