local H = require "packages.fengsui.hegemony_util"

local ruwu = fk.CreateSkill {
  name = "fengsui_heg__ruwu",
}

local function hasPileChange(data)
  return data and table.find(data, function(move)
    return move.toArea == Card.DrawPile or
      (move.fromArea == Card.DiscardPile and move.toArea ~= Card.DiscardPile)
  end) ~= nil
end

ruwu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, _, _, player, data)
    return player:isAlive() and player:hasShownSkill(self.name) and hasPileChange(data)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local choices = {}
    local place = H.inGeneralSkills(player, self.name)
    if place and H.allGeneralsRevealed(player) and H.hasGeneral(player, true) then
      table.insert(choices, "fengsui_heg__ruwu_hebi")
    end
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@!!companion") > 0
    end)
    if #targets > 0 then table.insert(choices, "fengsui_heg__ruwu_draw") end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = self.name,
      prompt = "#fengsui_heg__ruwu-choice",
    })
    if choice == "fengsui_heg__ruwu_hebi" then
      player:hideGeneral(place == "m")
      H.askToHebiOrTransform(room, player, self.name, false)
    else
      local chosen = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = self.name,
        prompt = "#fengsui_heg__ruwu-target",
        cancelable = false,
      })
      if #chosen > 0 and chosen[1]:isAlive() then room:drawCards(chosen[1], 1, self.name) end
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__ruwu-choice"] = "如晤：请选择一项",
  ["#fengsui_heg__ruwu-target"] = "如晤：选择一名有珠联璧合标记的角色摸一张牌",
  ["fengsui_heg__ruwu_hebi"] = "暗置另一张武将牌并合璧",
  ["fengsui_heg__ruwu_draw"] = "令一名有珠联璧合标记的角色摸一张牌",
}

return ruwu
