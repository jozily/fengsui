local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local lieying = fk.CreateSkill { name = "fengsui_heg__lieying", tags = { Skill.Limited } }
lieying:addEffect(fk.CardUsing, { can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("fengsui_heg__lieying_used") == 0 and
      data.card and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      data.tos and #data.tos == 1 and data.tos[1] ~= player
  end, on_cost = function(self, _, _, player) return player.room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__lieying-invoke" }) end,
    on_use = function(self, _, _, player, data)
      local room = player.room
      room:setPlayerMark(player, "fengsui_heg__lieying_used", 1)
      room:loseHp(player, 1)
      -- CardUsing 的 data 是 UseCardData；引擎检查不可响应目标时读取
      -- disresponsiveList，而不是 disresponsive 布尔字段。
      -- 烈荧「令此牌无法被响应」＝所有角色都不能用牌响应，不止这张牌的目标。
      -- 原来只写 data.tos，目标以外的人仍能出无懈/杀等响应，与规则不符。
      -- 用整表覆盖，对齐官方「无法响应」类技能（勘破/巧梦等）的写法。
      data.disresponsiveList = table.simpleClone(player.room.players)
    end })
return lieying

