local H = require "packages.hegemony.util"

local jincai = fk.CreateSkill{
  name = "fengsui_heg__jincai",
}

local damage_mark = "fengsui_heg__jincai_targets-round"

jincai:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jincai.name) and
      player:usedSkillTimes(jincai.name, Player.HistoryRound) == 0 and
      data.card.color == Card.Red and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = player.room.alive_players,
      skill_name = jincai.name,
      prompt = "#fengsui_heg__jincai-choose",
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, { to = chosen[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    local choice = room:askToChoice(to, {
      choices = { "fengsui_heg__jincai_draw", "fengsui_heg__jincai_red" },
      skill_name = jincai.name,
      prompt = "#fengsui_heg__jincai-choice::" .. player.id,
    })
    if choice == "fengsui_heg__jincai_draw" then
      to:drawCards(2, jincai.name)
      if to:isAlive() and H.getGeneralsRevealedNum(to) > 0 then
        H.doHideGeneral(room, to, to, jincai.name)
      end
      local targets = to:getTableMark(damage_mark)
      table.insertIfNeed(targets, player.id)
      room:setPlayerMark(to, damage_mark, targets)
    else
      room:setPlayerMark(to, "fengsui_heg__jincai_red-turn", 1)
    end
  end,
})

jincai:addEffect(fk.DamageCaused, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to and
      table.contains(player:getTableMark(damage_mark), data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
    local targets = player:getTableMark(damage_mark)
    table.removeOne(targets, data.to.id)
    player.room:setPlayerMark(player, damage_mark, #targets > 0 and targets or 0)
  end,
})

jincai:addEffect("prohibit", {
  global = true,
  prohibit_use = function(self, player, card)
    return player:getMark("fengsui_heg__jincai_red-turn") > 0 and
      card and card.color == Card.Red
  end,
})

return jincai
