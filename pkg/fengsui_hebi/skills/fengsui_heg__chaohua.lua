local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local chaohua = fk.CreateSkill { name = "fengsui_heg__chaohua" }

chaohua:addEffect("active", {
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:hasShownSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = U.FalseFunc,
  target_filter = function(self, player, to, selected)
    return #selected == 0 and to ~= player and H.getGeneralsRevealedNum(to) == 2
  end,
  on_use = function(self, room, effect)
    local from, target = effect.from, effect.tos[1]
    if not H.compareKingdomWith(from, target) then
      room:setPlayerMark(from, "fengsui_heg__chaohua_invalid-turn", 1)
      return
    end
    local place = room:askToChoice(from, {
      choices = { "fengsui_heg__chaohua_main", "fengsui_heg__chaohua_deputy" },
      skill_name = self.name,
    })
    local is_deputy = place == "fengsui_heg__chaohua_deputy"
    local gname = is_deputy and target.deputyGeneral or target.general
    local general = Fk.generals[gname]
    if not general then return end
    target:hideGeneral(is_deputy)
    U.prohibitReveal(target, is_deputy, self.name, "turn")
    local choices = { "fengsui_heg__chaohua_draw" }
    local limited = table.filter(general:getSkillNameList(true), function(name)
      local sk = Fk.skills[name]
      return sk and sk:hasTag(Skill.Limited) and target:usedSkillTimes(name, Player.HistoryGame) > 0
    end)
    if #limited > 0 then table.insert(choices, "fengsui_heg__chaohua_reset") end
    local choice = room:askToChoice(from, { choices = choices, skill_name = self.name })
    if choice == "fengsui_heg__chaohua_draw" then
      room:drawCards(target, 2, self.name)
    else
      local selected = room:askToChoice(from, { choices = limited, skill_name = self.name, prompt = "#fengsui_heg__chaohua-reset" })
      target:setSkillUseHistory(selected, 0, Player.HistoryGame)
    end
  end,
})

return chaohua
