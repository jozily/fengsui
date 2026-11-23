local huanghan = fk.CreateSkill {
  name = "fengsui_heg__huanghan",
}

local TIMES = "fengsui_heg__huanghan_times-round"
local HUANGHAN_MARK = "@[fengsui_heg__huanghan]"

-- 惶汉 mark：显示本轮发动次数（"惶汉 X"）
Fk:addQmlMark{
  name = "fengsui_heg__huanghan",
  how_to_show = function(_, value, p)
    if not p then return "0" end
    return tostring(p:getMark(TIMES) or 0)
  end,
  qml_data = function() return {} end,
  qml_path = function() return "" end,
}

-- 轮开始时触发一次 mark 重绘，使 -round 计数清零后显示同步归零
huanghan:addEffect(fk.RoundStart, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(huanghan.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, HUANGHAN_MARK, 1)
  end,
})

huanghan:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huanghan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local x = (data.card and data.card:getNameLength()) or 1
    if x < 1 then x = 1 end
    return player.room:askToSkillInvoke(player, {
      skill_name = huanghan.name,
      prompt = "#fengsui_heg__huanghan-invoke:::" .. x,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = (data.card and data.card:getNameLength()) or 1
    if x < 1 then x = 1 end
    local times = (player:getMark(TIMES) or 0) + 1
    room:setPlayerMark(player, TIMES, times)
    room:setPlayerMark(player, HUANGHAN_MARK, times)
    player:drawCards(x, huanghan.name)
    local n = math.min(times, #player:getCardIds("he"))
    if n > 0 then
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = huanghan.name,
        cancelable = false,
      })
    end
  end,
})

return huanghan
