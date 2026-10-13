local H = require "packages.fengsui.hegemony_util"
local dunmeng = fk.CreateSkill { name = "fengsui_heg__dunmeng", tags = { Skill.Limited } }

local function replaceReward(player, data)
  local room, killer = player.room, data.killer
  room:setPlayerMark(player, "fengsui_heg__dunmeng_used", 1)
  data.replaced = true
  killer:drawCards(2 * (room:getBanner("RoundCount") or 1), dunmeng.name)
  if killer:isAlive() and H.hasGeneral(killer, true) then
    H.transformGeneral(room, killer, false, true, 1, dunmeng.name)
  end
end

dunmeng:addEffect(H.KillRewardExecuting, {
  can_trigger = function(self, _, target, player, data)
    return target and data and not data.replaced and data.killer == target and
      target:isAlive() and target.kingdom ~= "unknown" and
      player:hasShownSkill(dunmeng.name) and
      player:usedSkillTimes(dunmeng.name, Player.HistoryGame) == 0 and
      player:getMark("fengsui_heg__dunmeng_used") == 0
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = dunmeng.name,
      prompt = "#fengsui_heg__dunmeng-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, _, player, data)
    replaceReward(player, data)
  end,
})

dunmeng:addTest(function()
  local used, drawn, transformed = {}, nil, nil
  local killer = {
    general = "fengsui_heg__wenqiao", deputyGeneral = "",
    isAlive = function() return true end,
    drawCards = function(_, n, reason) drawn = {n, reason} end,
  }
  local owner = {room = {
    setPlayerMark = function(_, p, key, value) used = {p, key, value} end,
    getBanner = function() return 4 end,
  }}
  local data = {killer = killer, replaced = false}
  replaceReward(owner, data)
  lu.assertTrue(data.replaced)
  lu.assertEquals(drawn, {8, dunmeng.name})
  lu.assertEquals(used[1], owner)
  lu.assertEquals(used[3], 1)
end)

return dunmeng
