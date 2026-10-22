local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local aishan = fk.CreateSkill { name = "fengsui_heg__aishan" }

aishan:addEffect(fk.HpChanged, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and player:hasSkill(self.name) and
      target.hp <= player.hp and H.getGeneralsRevealedNum(player) == 2 and
      H.getKingdom(target) ~= "unknown" and
      not table.contains(player:getTableMark("@fengsui_heg__aishan_kingdom-round"), H.getKingdom(target)) and
      not target:isKongcheng() and (target ~= player or target:getHandcardNum() >= 2)
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {skill_name = self.name, prompt = "#fengsui_heg__aishan-invoke::" .. target.id})
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    room:addTableMark(player, "@fengsui_heg__aishan_kingdom-round", H.getKingdom(target))
    local place = U.getSkillPlace(player, self.name)
    if place ~= nil then player:hideGeneral(place) end
    if player:isKongcheng() or target:isKongcheng() then return end
    local mine = room:askToChooseCards(player, { target = player, flag = "h", min = 1, max = 1, skill_name = self.name, prompt = "#fengsui_heg__aishan-card" })[1]
    local options = target:getCardIds("h")
    if target == player then table.removeOne(options, mine) end
    if #options == 0 then return end
    local theirs = room:askToCards(target, {min_num = 1, max_num = 1, include_equip = false,
      pattern = tostring(Exppattern{id = options}), skill_name = self.name, cancelable = false})[1]
    if not mine or not theirs then return end
    local a, b = Fk:getCardById(mine), Fk:getCardById(theirs)
    local color, suit, name = a.color == b.color, a.suit == b.suit, a.name == b.name
    room:showCards({mine}, player)
    room:showCards({theirs}, target)
    if color then room:obtainCard(player, {mine, theirs}, true, fk.ReasonPrey, player, self.name) end
    if suit and player:isAlive() then
      local ids = table.filter({mine, theirs}, function(id) return room:getCardOwner(id) == player end)
      if #ids > 0 then room:recastCard(ids, player, self.name) end
    end
    if name and player:isAlive() then H.transformGeneral(room, player, false, false, 1, self.name) end

  end,
})

return aishan
