local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local pijian = fk.CreateSkill {
  name = "fengsui_heg__pijian",
  tags = { Skill.DeputyPlace },
}

pijian:addEffect(fk.CardUsing, {
  global = true,
  can_refresh = function(self, _, target, player, data)
    return target and data and data.card and data.card.trueName ~= nil
  end,
  on_refresh = function(self, _, target, player, data)
    player.room:addTableMarkIfNeed(target, "fengsui_heg__pijian_names-turn", data.card.trueName)
  end,
})

pijian:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, _, target, player)
    if not target or target == player or target.phase ~= Player.Finish or
      not player:hasShownSkill(pijian.name) then return false end
    local names = target:getTableMark("fengsui_heg__pijian_names-turn")
    return table.find(player:getCardIds("h"), function(id)
      return table.contains(names, Fk:getCardById(id).trueName)
    end) ~= nil
  end,
  on_cost = function(self, event, target, player)
    local names = target:getTableMark("fengsui_heg__pijian_names-turn")
    local ids = table.filter(player:getCardIds("h"), function(id)
      return table.contains(names, Fk:getCardById(id).trueName)
    end)
    if #ids == 0 then return false end
    -- prompt 的第 4 段才是 %arg，只写 "::" .. target.id 时客户端不会替换。
    -- 这里列出手中实际存在的同名牌名，避免提示里出现无关牌名。
    local shownNames = {}
    for _, id in ipairs(ids) do
      table.insertIfNeed(shownNames, Fk:translate(Fk:getCardById(id).trueName))
    end
    -- 不能用 Room:askToChooseCard：它只接收 target/flag/prompt，传进去的
    -- pattern 会被整个忽略，客户端按 flag="h" 列出全部手牌，于是非同名牌
    -- 也能被选中弃置。改用项目内的列表选牌工具，候选牌就只有 ids。
    local id = U.chooseCardsFromList(player.room, player, ids, 1, 1,
      "#fengsui_heg__pijian-card::" .. target.id .. ":" ..
        table.concat(shownNames, "、"), pijian.name, false)[1]
    if id then event:setCostData(self, id); return true end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local id = event:getCostData(self)
    if id then room:showCards({id}, player); room:throwCard({id}, pijian.name, player, player) end
    if target:isAlive() and player:isAlive() then
      room:useVirtualCard("duel", nil, player, {target}, pijian.name, true)
    end
  end,
})

return pijian
