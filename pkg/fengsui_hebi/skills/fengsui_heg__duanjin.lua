local H = require "packages.fengsui.hegemony_util"

local duanjin = fk.CreateSkill{
  name = "fengsui_heg__duanjin",
}

-- 新版：武将牌被移除/变更后，重铸装备区所有牌，然后与一名其他同势力角色
-- 依次各获得一枚珠联璧合标记。不再需要副将易位。
local function addDuanjinEffect(triggerEvent)
  duanjin:addEffect(triggerEvent, {
    anim_type = "support",
    can_trigger = function(self, event, target, player, data)
      -- GeneralRemoved / GeneralTransformed 触发前曹涔的技能已被卸掉，
      -- 此处不能用 hasShownSkill 判断，否则技能永远无法发动。
      return target == player and player:isAlive() and
        data and data.origName == "fengsui_heg__caocen"
    end,
    on_cost = function(self, event, target, player, data)
      local room = player.room
      local targets = table.filter(room.alive_players, function(p)
        return p ~= player and H.compareKingdomWith(p, player)
      end)
      if #targets == 0 then return false end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#fengsui_heg__duanjin-choose",
        skill_name = duanjin.name,
        cancelable = true,
      })
      if #tos > 0 then
        event:setCostData(self, { to = tos[1] })
        return true
      end
    end,
    on_use = function(self, event, target, player, data)
      local room = player.room
      local to = event:getCostData(self).to
      local equips = player:getCardIds("e")
      if #equips > 0 then
        room:recastCard(equips, player, duanjin.name)
      end
      if player:isAlive() then
        H.addHegMark(player, "companion")
      end
      if to and to:isAlive() then
        H.addHegMark(to, "companion")
      end
    end,
  })
end

addDuanjinEffect(H.GeneralRemoved)
addDuanjinEffect(H.GeneralTransformed)

Fk:loadTranslationTable{
  ["#fengsui_heg__duanjin-choose"] = "断衿：选择一名其他同势力角色，依次获得珠联璧合标记",
}

return duanjin
