local H = require "packages.fengsui.hegemony_util"
local menyin = fk.CreateSkill {
  name = "fengsui_heg__menyin",
  tags = { Skill.Limited, Skill.MainPlace },
}

menyin:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(self.name) and player.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      H.isBigKingdomPlayer(player)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local candidates = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(p, player) and
        p.general ~= "anjiang" and p.deputyGeneral ~= "anjiang"
    end)
    if #candidates == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = candidates,
      min_num = 1,
      max_num = 1,
      skill_name = self.name,
      prompt = "#fengsui_heg__menyin-target",
    })
    local to = tos and tos[1]
    if not to then return end
    local choice = room:askToChoice(to, {
      choices = { "fengsui_heg__menyin_hebi", "fengsui_heg__menyin_hide" },
      skill_name = self.name,
      prompt = "#fengsui_heg__menyin-choice",
    })
    if choice == "fengsui_heg__menyin_hebi" then
      H.askToHebiOrTransform(room, to, self.name, false)
    else
      to:hideGeneral(true)
    end
  end,
})

return menyin
