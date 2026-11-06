local U = require "packages.utility.utility"

local hengwen = fk.CreateSkill {
  name = "fengsui_toaru__heg__hengwen",
  tags = { Skill.Limited },
}

local RECORD_MARK = "fengsui_toaru__heg__hengwen_record"

Fk:loadTranslationTable{
  ["fengsui_toaru__heg__hengwen"] = "恒温",
  [":fengsui_toaru__heg__hengwen"] = "限定技，出牌阶段，你可以记录一名角色的体力值与手牌数。当其体力值变化后，你可以令其体力恢复与手牌摸至记录数并清除此记录。",
  ["#fengsui_toaru__heg__hengwen"] = "恒温：记录一名角色的体力值与手牌数",
  ["#fengsui_toaru__heg__hengwen-invoke"] = "恒温：是否令 %dest 恢复至记录的体力与手牌数？",
  ["fengsui_toaru__heg__hengwen_record"] = "恒温",
}

hengwen:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_toaru__heg__hengwen",
  can_use = function(self, player)
    return player:usedSkillTimes(hengwen.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = U.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:isAlive()
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    room:setPlayerMark(effect.from, RECORD_MARK, {
      id = target.id,
      hp = target.hp,
      hand = target:getHandcardNum(),
    })
  end,
})

hengwen:addEffect(fk.HpChanged, {
  anim_type = "support",
  can_trigger = function(self, _, target, player)
    if not player:hasSkill(hengwen.name) or not target or target.dead then return false end
    local record = player:getTableMark(RECORD_MARK)
    return record and record.id == target.id and record.hp and target.hp ~= record.hp
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = hengwen.name,
      prompt = "#fengsui_toaru__heg__hengwen-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local record = player:getTableMark(RECORD_MARK)
    room:setPlayerMark(player, RECORD_MARK, 0)
    if target.dead then return end
    if target.hp < record.hp and target:isWounded() then
      room:recover {
        who = target,
        num = math.min(record.hp - target.hp, target.maxHp - target.hp),
        recoverBy = player,
        skillName = hengwen.name,
      }
    end
    local diff = (record.hand or 0) - target:getHandcardNum()
    if diff > 0 then target:drawCards(diff, hengwen.name) end
  end,
})

return hengwen
