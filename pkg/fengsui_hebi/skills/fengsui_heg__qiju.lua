local H = require "packages.fengsui.hegemony_util"
local qiju = fk.CreateSkill { name = "fengsui_heg__qiju", tags = { Skill.Limited } }
local function getOwner(room)
  if not room or not room.alive_players then return nil end
  return table.find(room.alive_players, function(p)
    return p:hasShownSkill(qiju.name) and H.inGeneralSkills(p, qiju.name) ~= nil and
      p:getMark("fengsui_heg__qiju_used") > 0
  end)
end
qiju:addEffect("active", {card_num=0,target_num=0,can_use=function(self,p) return p:hasShownSkill(self.name) and p:getMark("fengsui_heg__qiju_used")==0 end,card_filter=Util.FalseFunc,target_filter=Util.FalseFunc,on_use=function(self,room,effect)
 local p=effect.from;

room:setPlayerMark(p,"fengsui_heg__qiju_used",1);

local n=H.getGeneralsRevealedNum(p);

for _,x in ipairs(room.alive_players) do if x~=p and H.getGeneralsRevealedNum(x)~=n then room:changeKingdom(x,"unknown",true) end end

local users = table.filter(room.alive_players, function(x)
  return H.getGeneralsRevealedNum(x) == n and
    table.find(room.alive_players, function(q) return q.kingdom == "unknown" end) ~= nil
end)
room:sortByAction(users, p)
for _, user in ipairs(users) do
  if user:isAlive() then
    -- 戚举是「使用一张【杀】」，必须是实体杀（含技能转化，如武圣把红牌
    -- 当杀）：用 askToUseCard 走正常出牌，玩家手里没有可用的杀就拿不出来。
    -- 旧实现 askToUseVirtualCard 凭空造一张虚拟杀，等于「视为使用」，与
    -- 规则不符；下面 targetmod 已给出无距离/无次数/仅未确定势力的目标修正。
    local use = room:askToUseCard(user, {
      skill_name = qiju.name,
      pattern = "slash",
      prompt = "#fengsui_heg__qiju-slash", cancelable = true,
    })
    if use then
      room:useCard(use)
    end
    room:setPlayerMark(user, "fengsui_heg__qiju-turn", 1)
  end
end
end}
)
qiju:addEffect("targetmod", {
  global = true,
  mod_target_filter = function(self, player, to_select, selected, card)
    local owner = getOwner(player.room)
    return owner and H.getGeneralsRevealedNum(player) == H.getGeneralsRevealedNum(owner) and
      player:getMark("fengsui_heg__qiju-turn") == 0 and card and (card.name == "slash" or card.trueName == "slash") and
      to_select.kingdom == "unknown"
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    local owner = getOwner(player.room)
    return owner and H.getGeneralsRevealedNum(player) == H.getGeneralsRevealedNum(owner) and
      player:getMark("fengsui_heg__qiju-turn") == 0 and card and
      (card.name == "slash" or card.trueName == "slash") and to and to.kingdom == "unknown"
  end,
  bypass_distances = function(self, player, skill, card, to)
    local owner = getOwner(player.room)
    return owner and H.getGeneralsRevealedNum(player) == H.getGeneralsRevealedNum(owner) and
      player:getMark("fengsui_heg__qiju-turn") == 0 and card and
      (card.name == "slash" or card.trueName == "slash") and to and to.kingdom == "unknown"
  end,
})
qiju:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    local owner = getOwner(player.room)
    return owner and target == player and H.getGeneralsRevealedNum(player) == H.getGeneralsRevealedNum(owner) and
      player:getMark("fengsui_heg__qiju-turn") == 0 and data and data.card and (data.card.name == "slash" or data.card.trueName == "slash") and
      table.find(data.tos or {}, function(p) return p.kingdom == "unknown" end) ~= nil
  end,
  on_use = function(self, _, _, player)
    player.room:setPlayerMark(player, "fengsui_heg__qiju-turn", 1)
  end,
})
return qiju

