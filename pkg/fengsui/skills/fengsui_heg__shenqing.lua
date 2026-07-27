local H = require "packages.hegemony.util"
local U = require "packages.utility.utility"

local shenqing = fk.CreateSkill{
  name = "fengsui_heg__shenqing",
  tags = { Skill.Limited },
}

shenqing:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__shenqing-invoke",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shenqing.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    
    local all_gens = {}
    local gen2player = {}
    for _, p in ipairs(room.alive_players) do
       if p.general ~= "anjiang" and not p.general:startsWith("blank_") then 
          table.insert(all_gens, p.general) 
          gen2player[p.general] = p
       end
       if p.deputyGeneral ~= "anjiang" and not p.deputyGeneral:startsWith("blank_") then 
          table.insert(all_gens, p.deputyGeneral) 
          gen2player[p.deputyGeneral] = p
       end
    end
    
    if #all_gens < 2 then return end
    
    local choices = U.askToChooseGeneralsAndChoice(player, {
      skill_name = shenqing.name,
      generals = all_gens,
      prompt = "#fengsui_heg__shenqing-choose",
      min_num = 2,
      max_num = 2,
    })
    
    if #choices == 2 then
       local gen1, gen2 = choices[1], choices[2]
       local p1, p2 = gen2player[gen1], gen2player[gen2]
       
       -- 参考【离梦】：从武将原数据的 relatives["companion"] 获取真正的珠联璧合判定表
       local g1_info = Fk.generals[gen1]
       local g2_info = Fk.generals[gen2]
       local is_companion = (g1_info and g1_info:isCompanionWith(gen2)) or
         (g2_info and g2_info:isCompanionWith(gen1))
       
       if is_companion then
          if p1 and p1:isAlive() then H.addHegMark(p1, "companion") end
          if p2 and p2:isAlive() and p1 ~= p2 then H.addHegMark(p2, "companion") end
       else
          local options = {}
          if p1 and p1:isAlive() then table.insert(options, "shenqing_hebi::" .. p1.id) end
          if p2 and p2:isAlive() and p1 ~= p2 then table.insert(options, "shenqing_hebi::" .. p2.id) end
          table.insert(options, "Cancel")
          
          local choice = room:askToChoice(player, {
             choices = options,
             skill_name = shenqing.name,
             prompt = "#fengsui_heg__shenqing-hebi"
          })
          
          if choice ~= "Cancel" then
             local to_hebi = room:getPlayerById(tonumber(choice:match("::(%d+)$")))
             if to_hebi then
                H.askToHebiOrTransform(room, to_hebi, shenqing.name, false)
             end
          end
       end
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__shenqing"] = "申情",
  [":fengsui_heg__shenqing"] = "限定技，出牌阶段，你可以选择场上两张武将牌，若其中有满足【珠联璧合】的武将牌，则其所属角色各获得一枚【珠联璧合】标记；若均不满足，你可以令其中一位所属角色<a href='heg__hebi'>合璧</a> 或变更副将。",
  ["#fengsui_heg__shenqing-invoke"] = "申情：挑选两张武将牌进行判断",
  ["#fengsui_heg__shenqing-choose"] = "申情：请选择场上两张武将牌",
  ["#fengsui_heg__shenqing-hebi"] = "申情：未构成珠联璧合，选择一名角色令其合璧或变更副将",
  ["shenqing_hebi"] = "令 %src 合璧或变更副将",
}

return shenqing
