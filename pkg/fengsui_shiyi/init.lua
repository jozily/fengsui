local extension = Package:new("fengsui_shiyi")
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode", "fengsui_heg__mode" }

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_shiyi/skills")

-- 当前子包武将注册顺序
local zhouxuan = General:new(extension, "fengsui_heg__zhouxuan", "wei", 3)
zhouxuan:addSkills { "fengsui_heg__wumei", "fengsui_heg__jiemeng" }

local chenshou = General:new(extension, "fengsui_heg__chenshou", "shu", 3)
chenshou:addCompanions("fengsui_heg__qiaozhou", "fengsui_heg__limi")
chenshou:addSkills { "fengsui_heg__dianmo", "fengsui_heg__fuzai" }

local sunyuan = General:new(extension, "fengsui_heg__sunyuan", "wu", 4, 4, General.Female)
sunyuan:addCompanions("fengsui_heg__heji")
sunyuan:addSkills { "fengsui_heg__dongxin" }

local liuhui = General:new(extension, "fengsui_heg__liuhui", "qun", 4)
liuhui:addSkills { "fengsui_heg__jieshu" }

local wanghuifeng = General:new(extension, "fengsui_heg__wanghuifeng", "jin", 4, 4, General.Female)
wanghuifeng:addSkills { "fengsui_heg__dilie" }

local jiaxu = General:new(extension, "fengsui_heg__jiaxu", "fengsui_neutralall", 3)
jiaxu:addCompanions("hs__jiaxu")
jiaxu:addSkill("fengsui_heg__qingshi_jx")
jiaxu:addSkill("fengsui_heg__anshi")
jiaxu:addSkill("fengsui_heg__shuge")

local lusu = General:new(extension, "fengsui_heg__lusu", "fengsui_neutralall", 3)
lusu:addCompanions("hs__lusu")
lusu:addSkill("fengsui_heg__xiangkui")
lusu:addSkill("fengsui_heg__yangming")

local xushu = General:new(extension, "fengsui_heg__xushu", "fengsui_neutralall", 4)
xushu.mainMaxHpAdjustedValue = -1
xushu:addCompanions("ld__xushu")
xushu:addSkill("fengsui_heg__jiange")
xushu:addSkill("fengsui_heg__xiawang")
xushu:addSkill("fengsui_heg__yinyu")

local zhaoe = General:new(extension, "fengsui_heg__zhaoe", "fengsui_neutralall", 3)
zhaoe.gender = General.Female
zhaoe:addSkill("fengsui_heg__yanshi")
zhaoe:addSkill("fengsui_heg__xinren")

local xushao = General:new(extension, "fengsui_heg__xushao", "fengsui_neutralall", 3)
xushao:addCompanions("fengsui_heg__xujing")
xushao:addSkill("fengsui_heg__yingmen")
xushao:addSkill("fengsui_heg__pingjian")


local xinxianying = General:new(extension, "fengsui_heg__xinxianying", "wei", 3, 3, General.Female)
xinxianying:addSkills { "fengsui_heg__qingshi", "fengsui_heg__jiejie" }

local guotu = General:new(extension, "fengsui_heg__guotu", "qun", 3)
guotu:addSkills { "fengsui_heg__qushi", "fengsui_heg__weijieskill" }

local sunluban = General:new(extension, "fengsui_heg__sunluban", "wu", 3, 3, General.Female)
sunluban:addSkills { "fengsui_heg__zenhui", "fengsui_heg__jiaojin" }

local wangyi = General:new(extension, "fengsui_heg__wangyi", "wei", 3, 3, General.Female)
wangyi:addSkills { "fengsui_heg__zhenlie", "fengsui_heg__miji" }

local xiahoushi = General:new(extension, "fengsui_heg__xiahoushi", "shu", 3, 3, General.Female)
xiahoushi.hidden = true
xiahoushi:addCompanions("hs__zhangfei")
xiahoushi:addSkills { "fengsui_heg__qiaoshi", "fengsui_heg__xinmai" }


local frenda = General:new(extension, "fengsui_toaru__heg__frenda", "fengsui_neutralall", 3, 3, General.Female)
frenda:addSkills { "fengsui_toaru__heg__yinxian" }

local shokuhou = General:new(extension, "fengsui_toaru__heg__shokuhou", "fengsui_neutralall", 3, 3, General.Female)
shokuhou:addSkills { "fengsui_toaru__heg__duxin", "fengsui_toaru__heg__piruan" }

local misaka = General:new(extension, "fengsui_toaru__heg__misaka", "fengsui_neutralall", 4, 4, General.Female)
misaka:addSkills { "fengsui_toaru__heg__cipao", "fengsui_toaru__heg__junshi" }

local shirai = General:new(extension, "fengsui_toaru__heg__shirai", "fengsui_neutralall", 3, 3, General.Female)
shirai:addSkills { "fengsui_toaru__heg__shunyi", "fengsui_toaru__heg__fengji" }

-- Remake 备份也会作为技能骨架加载；校验官方骨架至少完整即可。
assert(#extension.skill_skels >= 18, "fengsui_shiyi must load the official skill skeletons")

Fk:loadTranslationTable{
  ["fengsui_shiyi"] = "烽燧燎原-拾遗",

  ["fengsui_heg__xinxianying"] = "辛宪英",
  ["fengsui_heg__xiahoushi"] = "夏侯涓",
  ["#fengsui_heg__xiahoushi"] = "柴结缘起",
  ["designer:fengsui_heg__xiahoushi"] = "公冶长风",
  ["illustrator:fengsui_heg__xiahoushi"] = "公冶长风",
  ["cv:fengsui_heg__xiahoushi"] = "暂无",
  ["fengsui_heg__qiaoshi"] = "樵拾",
  [":fengsui_heg__qiaoshi"] = "当有角色受到属性伤害后，你可以与其各摸一张牌，若为同势力角色，你可令其<a href='heg__hebi'>合璧</a>。",
  ["fengsui_heg__xinmai"] = "薪脉",
  [":fengsui_heg__xinmai"] = "出牌阶段限一次，你可以令一名角色获得本回合进入弃牌堆的所有【杀】，然后令其选择一项：1.受到来自你的一点雷属性伤害；2.若其武将牌均明置，暗置一张武将牌。",
  ["$fengsui_heg__qiaoshi1"] = "采樵南山下，拾君一片心。",
  ["$fengsui_heg__qiaoshi2"] = "山有木兮木成樵，心悦君兮君可知。",
  ["$fengsui_heg__xinmai1"] = "夏燕不羡黄金屋，只栖君家檐下巢。",
  ["$fengsui_heg__xinmai2"] = "红袖不解相思意，凭燕传语慰君心。",
  ["~fengsui_heg__xiahoushi"] = "可怜城头白发妪，至死不见征夫还。",
  ["#fengsui_heg__xinxianying"] = "才智耀天下",
  ["illustrator:fengsui_heg__xinxianying"] = "佚名",
  ["$fengsui_heg__qingshi1"] = "行路八千里，方可辨忠奸。",
  ["$fengsui_heg__qingshi2"] = "观其行，明其志，而后知心。",
  ["$fengsui_heg__jiejie1"] = "为谋大计，失小利亦无妨。",
  ["$fengsui_heg__jiejie2"] = "才思敏捷，方可识人喻事。",
  ["~fengsui_heg__xinxianying"] = "慧眼也难看清这乱世的尘埃。",

  ["fengsui_heg__guotu"] = "郭图",
  ["#fengsui_heg__guotu"] = "凶臣",
  ["illustrator:fengsui_heg__guotu"] = "厦门塔普",
  ["$fengsui_heg__qushi1"] = "将军天人之姿，可令四海归心。",
  ["$fengsui_heg__qushi2"] = "小小锦上之花，难表一腔敬意。",
  ["$fengsui_heg__weijieskill1"] = "败战之罪在你，休要多言！",
  ["$fengsui_heg__weijieskill2"] = "纵汝舌灿莲花，亦难逃死罪。",
  ["~fengsui_heg__guotu"] = "工于心计而不成事，匹夫怀其罪……",

  ["fengsui_heg__sunluban"] = "孙鲁班",
  ["#fengsui_heg__sunluban"] = "为虎作伥",
  ["illustrator:fengsui_heg__sunluban"] = "鬼画府",
  ["$fengsui_heg__zenhui1"] = "我的好妹妹，来世莫要生于帝王家。",
  ["$fengsui_heg__zenhui2"] = "至尊有诏，不从长公主旨，斩！",
  ["$fengsui_heg__jiaojin1"] = "恩情惩刑，皆是本公主的赏赐。",
  ["$fengsui_heg__jiaojin2"] = "本公主要做何事，还需你们说教？",
  ["~fengsui_heg__sunluban"] = "生于朱楼高阙，谈何亲情？",

  ["fengsui_heg__wangyi"] = "王异",
  ["#fengsui_heg__wangyi"] = "决意的巾帼",
  ["illustrator:fengsui_heg__wangyi"] = "zoo",
  ["$fengsui_heg__zhenlie1"] = "素颜风吹胭脂折，巾帼红妆贞烈战！",
  ["$fengsui_heg__zhenlie2"] = "贞洁烈志，与城共守。",
  ["$fengsui_heg__miji1"] = "共勉卒勋，不可顺逆转之意。",
  ["$fengsui_heg__miji2"] = "管仲入齐，立九合之功。",
  ["~fengsui_heg__wangyi"] = "去年花开君还在，今年花落复谁在。",


  ["fengsui_toaru"] = "学园都市",
  ["fengsui_toaru__heg"] = "学园都市",
  ["fengsui_toaru__heg__frenda"] = "芙兰达",
  ["fengsui_toaru__heg__shokuhou"] = "食蜂操祈",
  ["fengsui_toaru__heg__misaka"] = "御坂美琴",
  ["fengsui_toaru__heg__shirai"] = "白井黑子",
}

assert(#extension.generals == 19, "fengsui_shiyi must register exactly 19 generals")

-- 番外武将默认隐藏；五名常规中立者必须进入正常选将池。
local visible_neutral = {
  fengsui_heg__jiaxu = true, fengsui_heg__lusu = true, fengsui_heg__xushu = true,
  fengsui_heg__zhaoe = true, fengsui_heg__xushao = true,
}
for _, general in ipairs(extension.generals) do
  general.hidden = not visible_neutral[general.name]
end

return extension



