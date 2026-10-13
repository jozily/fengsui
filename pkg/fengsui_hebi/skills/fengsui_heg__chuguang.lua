local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local chuguang = fk.CreateSkill { name = "fengsui_heg__chuguang", tags = { Skill.Compulsory } }
local lockMark = "fengsui_heg__chuguang_locked_place"
local function sameKingdomPlayers(player)
  return table.filter(player.room.alive_players, function(p) return H.compareKingdomWith(player, p) end)
end

chuguang:addEffect(fk.AfterSkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local skillName = data and data.skill and data.skill:getSkeleton().name
    return target == player and player:hasShownSkill(self.name) and player:getMark(self.name .. "-round") == 0 and
      (skillName == "fengsui_heg__jiaosu" or skillName == "fengsui_heg__yaoming") and
      player:getMark("fengsui_heg__chuguang_count-round") == #sameKingdomPlayers(player)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local n = #sameKingdomPlayers(player)
    room:setPlayerMark(player, self.name .. "-round", 1)
    for _, deputy in ipairs({false, true}) do
      if H.hasGeneral(player, deputy) and (deputy and player.deputyGeneral or player.general) == "anjiang" then
        player:revealGeneral(deputy)
      end
    end
    if player.dead then return end
    local place = U.getSkillPlace(player, self.name)
    if place ~= nil then
      player:hideGeneral(place)
      local slot = place and "d" or "m"
      -- Use the engine's position-specific reveal lock, retaining other skills' locks.
      room:addTableMark(player, MarkEnum.RevealProhibited, slot)
      room:addTableMark(player, "@fengsui_heg__ban_reveal-round", Fk:translate(self.name) .. " 禁亮" .. Fk:translate(H.getActualGeneral(player, place)))
      room:setPlayerMark(player, lockMark, slot)
    end
    local candidates = sameKingdomPlayers(player)
    if #candidates == 0 then return end
    local tos = room:askToChoosePlayers(player, {targets = candidates, min_num = 1, max_num = 1,
      skill_name = self.name, prompt = "#fengsui_heg__chuguang-target", cancelable = false})
    if #tos > 0 then room:drawCards(tos[1], n, self.name) end
  end,
})

chuguang:addEffect(fk.RoundStart, {
  global = true,
  can_refresh = function(self, event, target, player) return target == player end,
  on_refresh = function(self, _, target, player)
    local room = player.room
    for _, p in ipairs(room.players) do
      local slot = p:getMark(lockMark)
      if type(slot) == "string" then
        local locks = p:getTableMark(MarkEnum.RevealProhibited)
        table.removeOne(locks, slot)
        room:setPlayerMark(p, MarkEnum.RevealProhibited, #locks > 0 and locks or 0)
        room:setPlayerMark(p, lockMark, 0)
      end
    end
  end,
})
return chuguang
