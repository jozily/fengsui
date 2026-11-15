local H = require "packages.fengsui.hegemony_util"
local D = require "packages.fengsui.pkg.fengsui_hebi.daoli_util"
_G.__fengsui_heg_daoli_stolen = _G.__fengsui_heg_daoli_stolen or {}
_G.__fengsui_heg_daoli_skills = _G.__fengsui_heg_daoli_skills or {}
_G.__fengsui_heg_daoli_pending = _G.__fengsui_heg_daoli_pending or {}

local function collectSkills(target)
  local result = {}
  for _, name in ipairs({ H.getActualGeneral(target, false), H.getActualGeneral(target, true) }) do
    local general = name and Fk.generals[name]
    if general then
      for _, skillName in ipairs(general:getSkillNameList(true)) do
        local skill = Fk.skills[skillName]
        if skill and not skill:hasTag(Skill.Lord) and not skill:hasTag(Skill.Limited) and
          not skill:hasTag(Skill.Compulsory) and not table.contains(result, skillName) then
          table.insert(result, skillName)
        end
      end
    end
  end
  return result
end

-- 按座位顺序取第一个候选，作为不发请求时的确定结果。
local function firstBySeat(candidates)
  local list = table.simpleClone(candidates)
  table.sort(list, function(a, b)
    if a.seat and b.seat then return a.seat < b.seat end
    return a.id < b.id
  end)
  return list[1]
end

local daoli_on_death = fk.CreateSkill { name = "#fengsui_heg__daoli_on_death", mute = true }
daoli_on_death:addEffect(fk.Death, {
  global = true,
  can_trigger = function(self, _, target, player)
    -- 悲秋那句「令一名其他同势力角色承接」是锁定技效果，必须发动；悼离是否
    -- 已用过不构成门槛。只有单独持有悼离（无悲秋）时才沿用限定技限制。
    return target == player and
      (player:hasSkill("fengsui_heg__beiqiu", true, true) or
        (player:usedSkillTimes("fengsui_heg__daoli", Player.HistoryGame) == 0 and
          player:hasSkill("fengsui_heg__daoli", true, true)))
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local candidates = table.filter(room.alive_players, function(p)
      return p ~= player and H.compareKingdomWith(player, p)
    end)
    if #candidates == 0 then return end
    -- 承接必须发动。选人弹窗的取消按钮是客户端 QML 的常驻控件，服务端
    -- cancelable=false 只能禁用、不能隐藏，而 Lua 扩展包覆盖不到 QML。
    -- 因此这里一律不发 Request，直接按座位顺序指定：弹窗不出现，也就
    -- 没有可按的取消键，同时避开死亡结算期间向控制者发请求的类型异常。
    D.prepare(room, firstBySeat(candidates), player)
  end,
})

for _, spec in ipairs(daoli_on_death.effect_spec_list) do
  if type(spec[3]) == "table" then spec[3].mute = true end
end

return daoli_on_death
