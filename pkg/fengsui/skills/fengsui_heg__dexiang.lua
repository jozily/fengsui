local H = require "packages.hegemony.util"

local dexiang = fk.CreateSkill{
  name = "fengsui_heg__dexiang",
}

dexiang:addEffect(fk.TargetSpecified, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    -- 回应角色必须含有德象，但不一定是他操作，这里需要从“任意同势力”找
    if not player:hasSkill(dexiang.name) then return false end
    if data.card.type ~= Card.TypeBasic and not data.card:isCommonTrick() then return false end
    if #data.tos ~= 1 then return false end
    
    local from = data.from
    local to = data.to
    
    -- 使用者附近含有与马伦同势力的角色（距离不大于1）
    local has_nearby_mate = false
    for _, p in ipairs(player.room.alive_players) do
       if H.compareKingdomWith(p, player) and p:distanceTo(from) <= 1 then
          has_nearby_mate = true
          break
       end
    end
    
    if not has_nearby_mate then return false end
    if player == to then return false end
    -- 马伦武将牌均明置
    return H.allGeneralsRevealed(player)
  end,
  on_cost = function(self, event, target, player, data)
     local room = player.room
     if room:askToSkillInvoke(player, { skill_name = dexiang.name, prompt = "#fengsui_heg__dexiang-invoke::" .. data.card:toLogString() }) then
        return true
     end
  end,
  on_use = function(self, event, target, player, data)
     local room = player.room
     -- 暗置一张自己的武将牌
     H.doHideGeneral(room, player, player, dexiang.name)
     -- 成为额外目标
     data:addTarget(player)
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__dexiang"] = "德象",
  [":fengsui_heg__dexiang"] = "与任意同势力角色距离不大于1的角色使用单体基本牌或普通锦囊牌指定目标后，若其不为目标且武将牌均明置，其可以暗置一张武将牌成为此牌的额外目标。",
  ["#fengsui_heg__dexiang-invoke"] = "德象：你可以暗置一张武将牌，成为 %arg 的额外目标",
}

return dexiang
