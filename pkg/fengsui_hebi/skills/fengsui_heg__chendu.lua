local H = require "packages.hegemony.util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local chendu = fk.CreateSkill{
  name = "fengsui_heg__chendu",
  tags = { Skill.Limited },
}

local function removedGeneralHasChendu(target, player, data)
  if target ~= player or not data.origName then return false end
  local general = Fk.generals[data.origName]
  return general and table.contains(general:getSkillNameList(), chendu.name)
end

chendu:addEffect(H.GeneralRemoved, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:isAlive() and
      (player:hasSkill(chendu.name) or removedGeneralHasChendu(target, player, data)) and
      player:usedSkillTimes(chendu.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = chendu.name, prompt = "#fengsui_heg__chendu-invoke::" .. target.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    
    -- Swap the target's main and deputy, then swap its deputy with an ally.
    if U.swapGenerals(room, target) then
       room:sendLog{
         type = "#ChenduSwapSelf",
         from = target.id,
         arg = chendu.name,
       }
    end
    
    -- 2. 与同一名势力角色副将易位
    local mates = table.filter(room.alive_players, function(p)
      return p ~= target and H.compareKingdomWith(p, target) and p.deputyGeneral ~= nil
    end)
    if #mates > 0 then
       local to_swap = room:askToChoosePlayers(target, {
         targets = mates, 
         min_num = 1, max_num = 1, 
         skill_name = chendu.name, 
         prompt = "#fengsui_heg__chendu-swap",
       })
       if #to_swap > 0 then
         H.swapDeputy(room, target, to_swap[1])
       end
    end
    
    if not target.dead then
        H.transformGeneral(room, target, false, false, 3) 
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__chendu"] = "陈笃",
  [":fengsui_heg__chendu"] = "限定技，当场上有角色移除武将牌时，你可以令其依次执行：1.主副将易位；2.与同一名势力角色主将或副将<a href='heg__yiwei'>易位</a>；3.变更副将。",
  ["#fengsui_heg__chendu-invoke"] = "陈笃：是否令 %dest 依次执行主副将易位、与同势力易位以及变更副将？",
  ["#fengsui_heg__chendu-swap"] = "陈笃：请选择一名同势力角色进行易位",
  ["#ChenduSwapSelf"] = "受【%arg】影响，%from 的主副将进行了易位",
}

return chendu
