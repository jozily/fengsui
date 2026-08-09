local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local jiyuan = fk.CreateSkill{
  name = "fengsui_heg__jiyuan",
  tags = { Skill.Limited },
}

jiyuan:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiyuan.name) and
      player:usedSkillTimes(jiyuan.name, Player.HistoryGame) == 0 and
      table.find(player.room.alive_players, function(p)
        return p ~= player and H.compareKingdomWith(p, player)
      end) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local chosen = player.room:askToChoosePlayers(player, {
      targets = table.filter(player.room.alive_players, function(p)
        return p ~= player and H.compareKingdomWith(p, player)
      end),
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__jiyuan-choose",
      skill_name = jiyuan.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {to = chosen[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to
    for _, p in ipairs(room.alive_players) do
      if p ~= player then room:addPlayerMark(p, "@fengsui_heg__jiyuan_peach", 1) end
    end
    U.removeGeneralByName(player, "fengsui_heg__yangyan")
    if to:isAlive() then
      if to.hp < to.maxHp then
        room:recover{who = to, num = to.maxHp - to.hp, recoverBy = player, skillName = jiyuan.name}
      end
      local delta = to.maxHp - to:getHandcardNum()
      if delta > 0 then
        to:drawCards(delta, jiyuan.name)
      elseif delta < 0 then
        room:askToDiscard(to, {
          min_num = -delta,
          max_num = -delta,
          include_equip = false,
          skill_name = jiyuan.name,
          prompt = "#fengsui_heg__jiyuan-discard:::" .. -delta,
          cancelable = false,
        })
      end
    end
  end,
})

jiyuan:addEffect(fk.AfterDying, {
  global = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@fengsui_heg__jiyuan_peach") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@fengsui_heg__jiyuan_peach", 0)
  end,
})

jiyuan:addEffect("prohibit", {
  global = true,
  prohibit_use = function(self, player, card)
    return player:getMark("@fengsui_heg__jiyuan_peach") > 0 and card and card.trueName == "peach"
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__jiyuan-choose"] = "霁愿：选择另一名同势力角色将体力值和手牌数调整至上限",
  ["#fengsui_heg__jiyuan-discard"] = "霁愿：请弃置 %arg 张手牌，将手牌数调整至体力上限",
  ["@fengsui_heg__jiyuan_peach"] = "霁愿：",
}

return jiyuan
