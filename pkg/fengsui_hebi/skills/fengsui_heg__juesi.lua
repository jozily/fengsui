local H = require "packages.fengsui.hegemony_util"
local juesi = fk.CreateSkill {
  name = "fengsui_heg__juesi",
  tags = { Skill.Compulsory },
}

juesi:addEffect(fk.TurnStart, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(self.name)
  end,
  on_use = function(self, _, target, player)
    for _, p in ipairs(player.room.alive_players) do
      if p ~= player and H.getGeneralsRevealedNum(p) ~= H.getGeneralsRevealedNum(player) then
        player.room:setPlayerMark(p, "fengsui_heg__juesi_original_kingdom", p.kingdom)
        player.room:setPlayerProperty(p, "kingdom", "unknown")
        player.room:setPlayerMark(p, "fengsui_heg__juesi_unknown-turn", 1)
      end
    end
  end,
})

juesi:addEffect(fk.TurnEnd, {
  global = true,
  can_refresh = function(self, _, target) return target and table.find(target.room.alive_players, function(p) return p:getMark("fengsui_heg__juesi_unknown-turn") > 0 end) ~= nil end,
  on_refresh = function(self, _, target)
    for _, p in ipairs(target.room.alive_players) do
      local original = p:getMark("fengsui_heg__juesi_original_kingdom")
      if type(original) == "string" and original ~= "" then target.room:setPlayerProperty(p, "kingdom", original) end
      target.room:setPlayerMark(p, "fengsui_heg__juesi_original_kingdom", 0)
      target.room:setPlayerMark(p, "fengsui_heg__juesi_unknown-turn", 0)
    end
  end,
})

return juesi
