local H = require "packages.fengsui.hegemony_util"

local yinbing = fk.CreateSkill{
  name = "fengsui_heg__yinbingRemake",
  tags = { Skill.Compulsory },
}

local yinbing_trigger = {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return (target == player or data.from == player) and player:hasSkill(yinbing.name) and player:usedSkillTimes(yinbing.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local injured = target
    local source = data.from
    if not injured or injured.dead or not source or source.dead then return end

    room:useVirtualCard("ice__slash", nil, injured, source, yinbing.name, true)
  end,
}
yinbing:addEffect(fk.Damaged, yinbing_trigger)
yinbing:addEffect(fk.Damage, yinbing_trigger)

yinbing:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.name == "ice__slash" and table.contains(data.card.skillNames, yinbing.name)
  end,
  on_use = function(self, event, target, player, data)
    local do_punish = true
    if data.damageDealt then
      for _, p in ipairs(data.tos) do
        if data.damageDealt[p] and data.damageDealt[p] > 0 then
          do_punish = false
          break
        end
      end
    end
    if do_punish and target:isAlive() then
      target:drawCards(2, yinbing.name)
      target.room:loseHp(target, 1, yinbing.name)
    end
  end,
})

return yinbing
