local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local lieying = fk.CreateSkill { name = "fengsui_heg__lieying", tags = { Skill.Limited } }
lieying:addEffect(fk.CardUsing, { can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(self.name) and player:getMark("fengsui_heg__lieying_used") == 0 and
      data.card and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      data.tos and #data.tos == 1 and data.tos[1] ~= player
  end, on_cost = function(self, _, _, player) return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__lieying-invoke" }) end,
    on_use = function(self, _, _, player, data)
      local room = player.room
      room:setPlayerMark(player, "fengsui_heg__lieying_used", 1)
      room:loseHp(player, 1)
      -- CardUsing 的 data 是 UseCardData；引擎检查不可响应目标时读取
      -- disresponsiveList，而不是 disresponsive 布尔字段。
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertTableIfNeed(data.disresponsiveList, data.tos)
    end })
return lieying

