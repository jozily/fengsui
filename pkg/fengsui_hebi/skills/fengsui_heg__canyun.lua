-- 残愠（贾褒）
-- 锁定技，你死亡后，杀死你的角色于执行奖惩后明置主将并变为野心家，
-- 然后所有野心家角色依次选择一项：1.移除副将并失去一点体力；2.获得〖枯根〗。
local H = require "packages.fengsui.hegemony_util"

local canyun = fk.CreateSkill {
  name = "fengsui_heg__canyun",
  tags = { Skill.Compulsory },
  related_skills = { "fengsui_heg__kugen" },
}

local function becomeWild(room, player)
  if not player or player.dead then return false end
  -- 先明置主将（暗置时才明置），再变为野心家。
  if player.general == "anjiang" then
    player:revealGeneral(false)
  end
  if H.isWildPlayer(player) then return false end
  room:setPlayerMark(player, "__heg_wild", 1)
  room:setPlayerProperty(player, "kingdom", "wild")
  -- 野心家当场建国：立刻结算势力选择
  H.wildChooseKingdom(player, player.general)
  return true
end

-- 奖惩在 fk.BuryVictim 结算（含除虫的 ignorePunishment），变野心家须放到其后的 fk.Deathed。
canyun:addEffect(fk.Deathed, {
  global = true,
  can_trigger = function(self, _, target, player)
    return target == player and player:hasSkill(canyun.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    -- 致命来源直接取死亡事件携带的 killer（即致命伤害的 from），
    -- 不再遍历全局伤害日志猜"最后一次"，避免后续伤害事件改写来源。
    local killer = data.killer
    if killer and killer ~= player then becomeWild(room, killer) end
    -- 所有野心家按座次依次选择一项：移除副将并失去一点体力，或获得“枯根”
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.dead then goto continue end
      if H.isWildPlayer(p) then
        local choice = room:askToChoice(p, {
          choices = { "fengsui_heg__canyun_remove", "fengsui_heg__canyun_gain" },
          skill_name = canyun.name,
          prompt = "#fengsui_heg__canyun-choice",
        })
        if choice == "fengsui_heg__canyun_remove" then
          if H.hasGeneral(p, true) then
            H.removeGeneral(p, true)
          end
          room:loseHp(p, 1, canyun.name)
        else
          room:handleAddLoseSkills(p, "fengsui_heg__kugen")
        end
      end
      ::continue::
    end
  end,
})

Fk:loadTranslationTable {
  ["#fengsui_heg__canyun-choice"] = "残愠：请选择一项",
  ["fengsui_heg__canyun_remove"] = "移除副将并失去一点体力",
  ["fengsui_heg__canyun_gain"] = "获得〖枯根〗",
}

return canyun
