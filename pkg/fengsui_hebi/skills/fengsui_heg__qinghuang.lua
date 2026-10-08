local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local qinghuang = fk.CreateSkill { name = "fengsui_heg__qinghuang" }
qinghuang:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return player:hasSkill(self.name) and target and target ~= player and H.compareKingdomWith(player, target)
      and player.room.current == target and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and data and data.card
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local previous = target:getMark("fengsui_heg__qinghuang-last")
    local key = (data.card.color or 0) * 100 + (data.card.type or 0)
    room:setPlayerMark(target, "fengsui_heg__qinghuang-last", key)
    if previous ~= 0 and math.floor(previous / 100) == (data.card.color or 0)
      and previous % 100 ~= (data.card.type or 0)
      and room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__qinghuang-swap::" .. target.id }) then
      if not U.swapGenerals(room, player) or not U.swapGenerals(room, target) then return end
      H.swapDeputy(room, player, target)
      U.swapGenerals(room, player); U.swapGenerals(room, target)
      room:setPlayerMark(player, "fengsui_heg__pinliu_pending", target.id)
      room:setPlayerMark(target, "fengsui_heg__pinliu_pending", player.id)
      room:drawCards(player, 1, self.name); room:drawCards(target, 1, self.name)
    end
  end,
})
qinghuang:addEffect(fk.TurnStart, { global = true, on_use = function(self, _, target) target.room:setPlayerMark(target, "fengsui_heg__qinghuang-last", 0) end })
return qinghuang
