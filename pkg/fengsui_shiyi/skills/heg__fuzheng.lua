local heg__fuzheng = fk.CreateSkill{
    name = "heg__fuzheng",
}

Fk:loadTranslationTable{
    ["heg__fuzheng"] = "辅政",
    [":heg__fuzheng"] = "一名角色死亡时，你可以选择一名与你势力相同的其他角色，你与其副将<a href='heg__yiwei'>易位</a>，"..
    "然后其回复1点体力。",

    ["#heg__fuzheng"] = "辅政：选择一名与你势力相同的其他角色，你与其副将易位并令其回复1点体力",
}

local H = require "packages.fengsui.hegemony_util"

heg__fuzheng:addEffect(fk.Death,{
    anim_type = "special",
    can_trigger = function (self, event, target, player, data)
        return player:hasSkill(heg__fuzheng.name) and table.find(player.room:getOtherPlayers(player), function (p)
            return H.compareKingdomWith(p, player)
        end)
    end,
    on_cost = function (self, event, target, player, data)
        local room = player.room
        local tos = table.filter(room:getOtherPlayers(player), function (p)
            return H.compareKingdomWith(p, player)
        end)
        if #tos > 0 then
            local to = room:askToChoosePlayers(player,{
                min_num = 1,
                max_num = 1,
                targets = tos,
                prompt = "#heg__fuzheng",
                skill_name = heg__fuzheng.name,
                cancelable = true,
            })
            if #to > 0 then
                event:setCostData(self, { tos = to })
                return true
            end
        end
    end,
    on_use = function (self, event, target, player, data)
        local room = player.room
        local to = event:getCostData(self).tos[1]
        H.SwapTwoPlayersDeputy(room, player, to)
        if to:isWounded() then
            room:recover({
                who = to,
                num = 1,
                skillName = heg__fuzheng.name
            })
        end
    end,
})

return heg__fuzheng
