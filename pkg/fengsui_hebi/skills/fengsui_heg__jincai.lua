local H = require "packages.fengsui.hegemony_util"

local jincai = fk.CreateSkill{
  name = "fengsui_heg__jincai",
}

local damage_sources_mark = "fengsui_heg__jincai_damage_sources-round"

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
    local all_choices = { "fengsui_heg__jincai_draw", "fengsui_heg__jincai_red" }
    local choices = { "fengsui_heg__jincai_red" }
    if H.allGeneralsRevealed(to) then
      table.insert(choices, 1, "fengsui_heg__jincai_draw")
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      all_choices = all_choices,
      skill_name = jincai.name,
      prompt = "#fengsui_heg__jincai-choice::" .. player.id,
    })
    if choice == "fengsui_heg__jincai_draw" then
      to:drawCards(2, jincai.name)
      if to:isAlive() then
        local hidden_place = H.doHideGeneral(room, to, to, jincai.name)
        local record = to:getTableMark(MarkEnum.RevealProhibited .. "-turn")
        table.insertIfNeed(record, hidden_place and "d" or "m")
        room:setPlayerMark(to, MarkEnum.RevealProhibited .. "-turn", record)
      end
      room:addTableMarkIfNeed(player, damage_sources_mark, to.id)
      room:setPlayerMark(to, "@fengsui_heg__jincai-round", player.id)
    else
      room:setPlayerMark(to, "fengsui_heg__jincai_red-turn", 1)
    end
  end,
})

jincai:addEffect(fk.DamageInflicted, {
  global = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.from and
      table.contains(player:getTableMark(damage_sources_mark), data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
    local sources = player:getTableMark(damage_sources_mark)
    table.removeOne(sources, data.from.id)
    player.room:setPlayerMark(player, damage_sources_mark, #sources > 0 and sources or 0)
    if data.from:getMark("@fengsui_heg__jincai-round") == player.id then
      player.room:setPlayerMark(data.from, "@fengsui_heg__jincai-round", 0)
    end
  end,
})

jincai:addEffect("prohibit", {
  global = true,
  prohibit_use = function(self, player, card)
    return player:getMark("fengsui_heg__jincai_red-turn") > 0 and
      card and card.color == Card.Red
  end,
})

Fk:loadTranslationTable{
  ["@fengsui_heg__jincai-round"] = "矜才：",
}

return jincai
