local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local hexi = fk.CreateSkill { name = "fengsui_heg__hexiRemake3" }

hexi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, _, _, player, data)
    return player:hasSkill(self.name) and player.phase ~= Player.Draw and
      table.find(data or {}, function(move)
        return move.to == player and move.toArea == Card.PlayerHand and move.moveInfo and #move.moveInfo > 0
      end) ~= nil and #player:getCardIds("e") > 0
  end,
  on_cost = function(self, event, _, player)
    local room = player.room
    local equips = player:getCardIds("e")
    local ids = U.chooseCardsFromList(room, player, equips, 1, 1, "#fengsui_heg__hexi-move", self.name, true)
    if #ids == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = table.filter(room.alive_players, function(p)
        return p ~= player and player:canMoveCardInBoardTo(p, ids[1])
      end), min_num = 1, max_num = 1, cancelable = true,
      skill_name = self.name, prompt = "#fengsui_heg__hexi-choose",
    })
    if #tos == 0 then return false end
    event:setCostData(self, { card = ids[1], to = tos[1] })
    return true
  end,
  on_use = function(self, event, _, player)
    local room = player.room
    local cost = event:getCostData(self)
    local target = cost.to
    room:moveCardTo(Fk:getCardById(cost.card), Card.PlayerEquip, target, fk.ReasonJustMove, self.name, nil, false, player)
    if not target:isAlive() then return end
    local choices = { "fengsui_heg__hexi_damage" }
    if H.allGeneralsRevealed(target) then table.insert(choices, "fengsui_heg__hexi_hide") end
    local choice = room:askToChoice(player, {
      choices = choices, skill_name = self.name, prompt = "#fengsui_heg__hexi-choice",
    })
    if choice == "fengsui_heg__hexi_damage" then
      local current = room.current
      if current and current:isAlive() then
        room:damage { from = target, to = current, damage = 1, skillName = self.name }
      end
    else
      local place = room:askToChoice(player, {
        choices = { "fengsui_heg__hexi_main", "fengsui_heg__hexi_deputy" },
        skill_name = self.name, prompt = "#fengsui_heg__hexi-place",
      })
      local hidden = place == "fengsui_heg__hexi_deputy"
      target:hideGeneral(hidden)
      U.prohibitReveal(target, hidden, self.name, "turn")
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__hexi-move"] = "貉隙：选择装备区的一张牌",
  ["#fengsui_heg__hexi-choose"] = "貉隙：选择一名其他角色",
  ["fengsui_heg__hexi_damage"] = "令其对当前回合角色造成1点伤害",
  ["fengsui_heg__hexi_hide"] = "暗置其一张武将牌且本回合无法明置",
  ["fengsui_heg__hexi_main"] = "暗置主将",
  ["fengsui_heg__hexi_deputy"] = "暗置副将",
  ["#fengsui_heg__hexi-place"] = "貉隙：选择暗置的武将牌",
}

return hexi
