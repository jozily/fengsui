local wushuang = fk.CreateSkill {
    name = "hs__wushuang",
    tags = { Skill.Compulsory },
}

---@type TrigSkelSpec<AimFunc>
local wushuang_spec = {
    on_use = function(self, event, target, player, data)
        local to = (event == fk.TargetConfirmed and data.card.trueName == "duel") and data.from or data.to
        data:setResponseTimes(2, to)
    end,
}

wushuang:addEffect(fk.TargetSpecified, {
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(wushuang.name) and
            table.contains({ "slash", "duel" }, data.card.trueName)
    end,
    on_use = wushuang_spec.on_use,
})

wushuang:addEffect(fk.TargetConfirmed, {
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(wushuang.name) and data.card.trueName == "duel"
    end,
    on_use = wushuang_spec.on_use,
})

wushuang:addEffect(fk.AfterCardTargetDeclared, {
    mute = true,
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(wushuang.name) then
            return false
        end
        if data.card.trueName == "duel" and target == player and not data.card:isConverted() then
            local current_targets = data:getAllTargets()
            for _, p in ipairs(player.room.alive_players) do
                if not table.contains(current_targets, p) and not player:isProhibited(p, data.card) and
                    data.card.skill:modTargetFilter(p, current_targets, target, data.card, true) then
                    return true
                end
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        local current_targets = data:getAllTargets()
        local targets = {}
        for _, p in ipairs(room:getOtherPlayers(player, true, false)) do
            if not table.contains(current_targets, p) and not player:isProhibited(p, data.card) and
                data.card.skill:modTargetFilter(p, current_targets, target, data.card, true) then
                table.insert(targets, p)
            end
        end
        local tos = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 2,
            prompt = "#hs__wushuang-choose:::" .. data.card:toLogString(),
            skill_name = wushuang.name,
            cancelable = true,
        })
        if #tos > 0 then
            event:setCostData(self, { tos = tos })
            return true
        end
    end,
    on_use = function(self, event, target, player, data)
        table.insertTable(data.tos, event:getCostData(self).tos)
    end,
})

Fk:loadTranslationTable {
    ["hs__wushuang"] = "无双",
    [":hs__wushuang"] = "锁定技，①当你使用【杀】指定目标后，其使用【闪】抵消此【杀】的方式改为需连续使用两张【闪】；当你使用【决斗】指定目标后，或当你成为【决斗】的目标后，你令其打出【杀】响应此【决斗】的方式改为需连续打出两张【杀】；" ..
        "②你使用的非转化【决斗】能选择至多三名角色为目标。",
    ["#hs__wushuang-choose"] = "无双：你可以为 %arg 增加至多两个目标",

    ["$hs__wushuang1"] = "谁能挡我！",
    ["$hs__wushuang2"] = "神挡杀神，佛挡杀佛！",
}

return wushuang
