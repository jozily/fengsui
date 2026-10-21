local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local aishan = fk.CreateSkill { name = "fengsui_heg__aishan" }

aishan:addEffect(fk.HpChanged, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and player:hasShownSkill(self.name) and H.compareKingdomWith(player, target) and
      target.hp <= player.hp and H.getGeneralsRevealedNum(player) == 2 and
      not table.contains(player:getTableMark("@fengsui_heg__aishan_kingdom-round"), H.getKingdom(target))
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:addTableMark(player, "@fengsui_heg__aishan_kingdom-round", H.getKingdom(target))
    local place = U.getSkillPlace(player, self.name)
    if place ~= nil then player:hideGeneral(place) end
    if player:isNude() or target:isNude() then return end
    local mine = room:askToChooseCards(player, { target = player, flag = "he", min = 1, max = 1, skill_name = self.name, prompt = "#fengsui_heg__aishan-card" })[1]
    local theirs = room:askToChooseCards(player, { target = target, flag = "he", min = 1, max = 1, skill_name = self.name, prompt = "#fengsui_heg__aishan-card" })[1]
    if not mine or not theirs then return end
    local a, b = Fk:getCardById(mine), Fk:getCardById(theirs)
    if a:compareColorWith(b) then room:obtainCard(player, { mine, theirs }, true, fk.ReasonPrey, player, self.name) end
    if a.suit == b.suit then room:recastCard({ mine, theirs }, player, self.name) end
    if a.name == b.name and place ~= nil and not player.dead then H.transformGeneral(room, player, false, false, 1, self.name) end
  end,
})

return aishan
