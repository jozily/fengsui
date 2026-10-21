local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local chaohua = fk.CreateSkill {name = "fengsui_heg__chaohua"}
chaohua:addEffect("active", {
  card_num = 0, target_num = 1,
  can_use = function(self, player)
    return player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = U.FalseFunc,
  target_filter = function(self, player, to, selected)
    return #selected == 0 and H.allGeneralsRevealed(to)
  end,
  on_use = function(self, room, effect)
    local from, target = effect.from, effect.tos[1]
    local limited = {}
    for _, deputy in ipairs({false, true}) do
      local general = Fk.generals[H.getActualGeneral(target, deputy)]
      if general then
        for _, name in ipairs(general:getSkillNameList(true)) do
          local sk = Fk.skills[name]
          if sk and sk:hasTag(Skill.Limited) and target:usedSkillTimes(name, Player.HistoryGame) > 0 then
            table.insertIfNeed(limited, name)
          end
        end
      end
    end
    local deputy = room:askToChoice(from, {choices = {"mainGeneral", "deputyGeneral"}, skill_name = self.name}) == "deputyGeneral"
    target:hideGeneral(deputy)
    local choices = {"fengsui_heg__chaohua_draw"}
    if #limited > 0 and from:getMark(self.name .. "_removed") == 0 then table.insert(choices, "fengsui_heg__chaohua_reset") end
    local choice = room:askToChoice(from, {choices = choices, skill_name = self.name})
    if choice == "fengsui_heg__chaohua_reset" then
      local name = room:askToChoice(from, {choices = limited, skill_name = self.name})
      target:setSkillUseHistory(name, 0, Player.HistoryGame)
      room:setPlayerMark(from, self.name .. "_removed", 1)
    else
      U.prohibitReveal(target, deputy, self.name, "turn")
      if target:isAlive() then target:drawCards(2, self.name) end
    end
  end,
})
return chaohua
