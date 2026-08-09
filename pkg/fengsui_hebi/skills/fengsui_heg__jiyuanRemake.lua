local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local jiyuan = fk.CreateSkill{
  name = "fengsui_heg__jiyuanRemake",
  tags = { Skill.Limited },
}

local remove_mark = "fengsui_heg__jiyuanRemake_remove"
local remove_place_mark = "fengsui_heg__jiyuanRemake_remove_place"

jiyuan:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiyuan.name) and
      player:usedSkillTimes(jiyuan.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local chosen = room:askToChoosePlayers(player, {
      targets = table.filter(room.alive_players, function(p)
        return H.compareKingdomWith(p, player)
      end),
      min_num = 1,
      max_num = 1,
      prompt = "#fengsui_heg__jiyuanRemake-choose",
      skill_name = jiyuan.name,
      cancelable = true,
    })
    if #chosen > 0 then
      event:setCostData(self, {
        to = chosen[1],
        is_deputy = U.getSkillPlace(player, jiyuan.name),
      })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local to = cost_data.to
    if to.hp < to.maxHp then
      room:recover{
        who = to,
        num = to.maxHp - to.hp,
        recoverBy = player,
        skillName = jiyuan.name,
      }
    end
    local delta = to.maxHp - to:getHandcardNum()
    if delta > 0 then
      to:drawCards(delta, jiyuan.name)
    elseif delta < 0 then
      room:askToDiscard(to, {
        min_num = -delta,
        max_num = -delta,
        include_equip = false,
        prompt = "#fengsui_heg__jiyuanRemake-discard:::" .. -delta,
        skill_name = jiyuan.name,
        cancelable = false,
      })
    end
    if to:isAlive() then
      H.transformGeneral(room, to, false, true)
    end
    room:setPlayerMark(player, remove_mark, 1)
    room:setPlayerMark(player, remove_place_mark, cost_data.is_deputy and 2 or 1)
  end,
})

jiyuan:addEffect(fk.AfterDying, {
  global = true,
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark(remove_mark) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, remove_mark, 0)
    if player:isAlive() then
      H.removeGeneral(player, player:getMark(remove_place_mark) == 2)
    end
    player.room:setPlayerMark(player, remove_place_mark, 0)
  end,
})

return jiyuan
