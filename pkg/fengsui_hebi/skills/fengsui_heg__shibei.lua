-- 矢北（国战版）：锁定技，当你受到伤害后，若此伤害是你本回合第一次受到的伤害，
-- 你回复1点体力；否则你失去1点体力。
-- 此技能由「酣世」在额外回合内向所有角色临时赋予，回合结束时收回。
local shibei = fk.CreateSkill {
  name = "fengsui_heg__shibei",
  tags = { Skill.Compulsory },
}

local countMark = "fengsui_heg__shibei_count-turn"
-- 与酣世共用：标记「正在酣世给予的额外回合中」
local activeMark = "fengsui_heg__hanshi_shibei"

shibei:addEffect(fk.Damaged, {
  can_trigger = function(self, _, target, player)
    return target == player and player:isAlive() and player:hasSkill(self.name, true)
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local times = player:getMark(countMark)
    room:addPlayerMark(player, countMark, 1)
    if times == 0 then
      room:recover {
        who = player,
        num = 1,
        recoverBy = player,
        skillName = shibei.name,
      }
    elseif player:isAlive() then
      room:loseHp(player, 1, shibei.name)
    end
  end,
})

-- 额外回合结束时收回矢北。挂在本技能上执行，只要场上还有角色持有矢北就能收尾，
-- 不依赖给予者是否存活；multiple 拥有者各判定一次，用标记保证只执行一次。
-- 走 on_trigger：收回是纯事务性动作，不该产生技能效果（否则会在界面上留下一条
-- "发动矢北"的提示，甚至因为效果技没有可见译文而显示成空标题）。
-- 收尾要稳健：谁身上有 activeMark（酣世的额外回合发起者）就在谁的回合
-- 结束时收回。旧实现 can_trigger 要求 target==player 且 target 自己带 mark，
-- 但效果挂在矢北上、player 是「当前被询问的持有者」；当额外回合发起者已经
-- 死亡或其 activeMark 因故提前清零时，这个条件永远不成立，矢北就留在部分
-- 角色身上不走了（用户报的 bug）。改成 global 扫描：任意角色回合结束时，
-- 只要场上还有人带 activeMark，就由该回合结束者触发一次全场收回。
shibei:addEffect(fk.TurnEnd, {
  global = true,
  priority = 5,
  can_trigger = function(self, _, target, player)
    if not target or target ~= player then return false end
    local room = player.room
    if not room then return false end
    for _, p in ipairs(room.players) do
      if p:getMark(activeMark) > 0 then return true end
    end
    return false
  end,
  on_trigger = function(self, _, target)
    local room = target.room
    -- 清掉所有 activeMark，再用「所有玩家」统一移除矢北（含已死亡者），
    -- 保证不留残留。
    for _, p in ipairs(room.players) do
      if p:getMark(activeMark) > 0 then room:setPlayerMark(p, activeMark, 0) end
      room:handleAddLoseSkills(p, "-" .. shibei.name, nil, false)
    end
  end,
})

return shibei
