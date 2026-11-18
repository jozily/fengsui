local H = require "packages.fengsui.hegemony_util"
local menyin = fk.CreateSkill {
  name = "fengsui_heg__menyin",
  tags = { Skill.Limited, Skill.MainPlace },
}

menyin:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, _, target, player)
    return target == player and player:hasShownSkill(self.name) and
      H.inGeneralSkills(player, self.name) == "m" and player.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      H.isBigKingdomPlayer(player)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local candidates = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player) and
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
    -- 门荫只有「选择是否合璧」一个动作，规则里没有「暗置武将牌」这个选项。
    -- 旧代码给了「合璧 / 暗置武将牌」二选一，属于凭空多出的错误选项；这里
    -- 直接走合璧 helper，cancelable=true 让它内部问「是否合璧（确定/取消）」。
    H.askToHebiOrTransform(room, to, self.name, true)
  end,
})

return menyin
