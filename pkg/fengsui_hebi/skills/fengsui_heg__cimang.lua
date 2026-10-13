local cimang = fk.CreateSkill { name = "fengsui_heg__cimang" }

cimang:addEffect(fk.GeneralRevealed, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self.name) and data and
      (data.m == "fengsui_heg__xunguan" or data.d == "fengsui_heg__xunguan") and
      #player.room.draw_pile > 0
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name, prompt = "#fengsui_heg__cimang-invoke",
    })
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local id = room.draw_pile[#room.draw_pile]
    if not id then return end
    room:obtainCard(player, id, true, fk.ReasonPrey, player, self.name)
    if player.dead or room:getCardOwner(id) ~= player then return end
    room:askToUseRealCard(player, {
      pattern = {id}, skill_name = self.name, cancelable = false,
      prompt = "#fengsui_heg__cimang-use",
      extra_data = { bypass_distances = true, bypass_times = true, extraUse = true },
    })
  end,
})

return cimang
