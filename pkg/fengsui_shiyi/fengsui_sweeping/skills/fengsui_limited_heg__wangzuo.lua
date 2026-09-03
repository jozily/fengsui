local H = require "packages.hegemony.util"
local wangzuo = fk.CreateSkill {
  name = "fengsui_limited_heg__wangzuo",
  tags = { Skill.Compulsory, Skill.DeputyPlace },
}

local kingdomSkills = {
  wei = { "hs__fangzhu", "jianan__qiaobian" },
  shu = { "ld__kanpo", "jianglue" },
  wu = { "duoshi", "hs__yinghun" },
  qun = { "qianhuan", "xiongsuan" },
  jin = { "heg__chengguan", "heg__shunfu" },
}

Fk:loadTranslationTable {
  ["fengsui_limited_heg__wangzuo"] = "王佐",
  [":fengsui_limited_heg__wangzuo"] = "锁定技，此武将牌只可放于副将。你根据主将势力获得下列技能：魏：<a href=':hs__fangzhu'>放逐</a>/<a href=':jianan__qiaobian'>巧变</a>；蜀：<a href=':ld__kanpo'>看破</a>/<a href=':jianglue'>将略</a>；吴：<a href=':duoshi'>度势</a>/<a href=':hs__yinghun'>英魂</a>；群：<a href=':qianhuan'>千幻</a>/<a href=':xiongsuan'>凶算</a>；晋：<a href=':heg__chengguan'>承冠</a>/<a href=':heg__shunfu'>瞬覆</a>。若你的当前体力值不小于2，获得斜线后的技能，否则获得斜线前的技能。",
}

local function wanted(player)
  local main = Fk.generals[player:getMark("__heg_general")]
  local list = main and kingdomSkills[main.kingdom]
  return list and list[player.hp >= 2 and 2 or 1]
end

local function update(player)
  local room = player.room
  local old = player:getMark("fengsui_limited_heg__wangzuo_skill")
  local new = wanted(player)
  if old == new then return end
  if old ~= 0 then room:handleAddLoseSkills(player, "-" .. old, nil, true, false) end
  if new then room:handleAddLoseSkills(player, new, nil, true, false) end
  room:setPlayerMark(player, "fengsui_limited_heg__wangzuo_skill", new or 0)
end

for _, event in ipairs { fk.GeneralRevealed, fk.HpChanged } do
  wangzuo:addEffect(event, {
    can_refresh = function(self, e, target, player, data)
      return target == player and player:hasSkill(wangzuo.name)
    end,
    on_refresh = function(self, e, target, player, data) update(player) end,
  })
end

return wangzuo
