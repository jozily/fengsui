local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local hexi = fk.CreateSkill { name = "fengsui_heg__hexi" }

hexi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, _, _, player, data)
    return player:hasSkill(self.name) and player.phase ~= Player.Draw and
      table.find(data or {}, function(move)
        return move.to == player and move.moveInfo and #move.moveInfo > 0
      end) ~= nil
  end,
  on_cost = function(self, event, _, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p ~= player and #p:getCardIds("ej") > 0
    end)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets, min_num = 1, max_num = 1, cancelable = true,
      skill_name = self.name, prompt = "#fengsui_heg__hexi-choose",
    })
    if #tos > 0 then
      event:setCostData(self, { to = tos[1] })
      return true
    end
  end,
  on_use = function(self, event, _, player)
    local room = player.room
    local to = event:getCostData(self).to
    if not to:isAlive() then return end
    local moved = room:askToMoveCardInBoard(player, {
      target_one = player,
      target_two = to,
      skill_name = self.name,
    })
    if not moved or not moved.card then return end
    local receiver = moved.to
    if not receiver or not receiver:isAlive() then return end
    local choices = { "fengsui_heg__hexi_damage" }
    if H.allGeneralsRevealed(receiver) then
      table.insert(choices, "fengsui_heg__hexi_hide")
    end
    local choice = room:askToChoice(receiver, {
      choices = choices, skill_name = self.name, prompt = "#fengsui_heg__hexi-choice",
    })
    if choice == "fengsui_heg__hexi_damage" then
      local current = room.current
      if current and current:isAlive() then
        room:damage { from = current, to = receiver, damage = 1, skillName = self.name }
      end
    else
      local place = room:askToChoice(receiver, {
        choices = { "fengsui_heg__hexi_main", "fengsui_heg__hexi_deputy" },
        skill_name = self.name, prompt = "#fengsui_heg__hexi-place",
      })
      local hidden = place == "fengsui_heg__hexi_deputy"
      receiver:hideGeneral(hidden)
      U.prohibitReveal(receiver, hidden, self.name, "turn")
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__hexi-choose"] = "合隙：选择一名其他角色",
  ["fengsui_heg__hexi_damage"] = "令当前回合角色对其造成1点伤害",
  ["fengsui_heg__hexi_hide"] = "若其武将牌均明置，暗置其一张武将牌且本回合无法明置",
  ["fengsui_heg__hexi_main"] = "暗置主将",
  ["fengsui_heg__hexi_deputy"] = "暗置副将",
  ["#fengsui_heg__hexi-place"] = "合隙：选择暗置的武将牌",
}

return hexi
