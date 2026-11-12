local extension = Package:new("fengsui_liwu")
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "new_heg_mode", "fengsui_heg__mode" }

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_liwu/skills")

-- 当前子包武将注册顺序
local renwan = General:new(extension, "fengsui_heg__renwan", "wei", 3, 3, General.Female)
renwan:addSkills { "fengsui_heg__lixi", "fengsui_heg__juansui" }

local yanrou = General:new(extension, "fengsui_heg__yanrou", "wei", 4)
yanrou:addCompanions("hs__caocao")
yanrou:addSkills { "fengsui_heg__choutao", "fengsui_heg__yongfan" }

local sunsuo = General:new(extension, "fengsui_heg__sunsuo", "wei", 3, 3, General.Female)
sunsuo:addSkills { "fengsui_heg__fenshuang", "fengsui_heg__yingmian" }

local liuxun = General:new(extension, "fengsui_heg__liuxun", "wei", 3,3, General.Female)
liuxun:addSkill("fengsui_heg__neixi")
liuxun:addSkill("fengsui_heg__wuli")

local guozhao = General:new(extension, "fengsui_heg__guozhao", "wei", 3, 3, General.Female)
guozhao:addCompanions("hs__caopi")
guozhao:addSkills { "fengsui_heg__zunwei", "fengsui_heg__zunwei_vs", "fengsui_heg__jiaoyu" }

local mamiao = General:new(extension, "fengsui_heg__mamiao", "shu", 4)
mamiao:addCompanions("fengsui_heg__lixian")
mamiao:addSkill("fengsui_heg__zhangguan")

local zhugezhan = General:new(extension, "fengsui_heg__zhugezhan", "shu", 4)
zhugezhan.mainMaxHpAdjustedValue = -1
zhugezhan:addCompanions("hs__zhugeliang")
zhugezhan:addSkills { "fengsui_heg__dishang", "fengsui_heg__fuyin" }

local lixian = General:new(extension, "fengsui_heg__lixian", "shu", 3, 3, General.Female)
lixian:addCompanions("fengsui_heg__mamiao")
lixian:addSkills { "fengsui_heg__xunyun", "fengsui_heg__zhengchi" }

local fengsui_heg__xujing = General:new(extension, "fengsui_heg__xujing", "shu", 3)
fengsui_heg__xujing:addCompanions("ld__fazheng")
fengsui_heg__xujing:addSkill("fengsui_heg__yuanyi")
fengsui_heg__xujing:addSkill("fengsui_heg__caixia")

local fengsui_heg__limi = General:new(extension, "fengsui_heg__limi", "shu", 3)
fengsui_heg__limi:addCompanions("fengsui_heg__qiaozhou", "fengsui_heg__chenshou")
fengsui_heg__limi:addSkill("fengsui_heg__ciying")
fengsui_heg__limi:addSkill("fengsui_heg__chendu")

local zhangyu = General:new(extension, "fengsui_heg__zhangyu", "shu", 3)
zhangyu:addSkills { "fengsui_heg__yuzhao", "fengsui_heg__gumeng" }

local wuxian = General:new(extension, "fengsui_heg__wuxian", "shu", 3, 3, General.Female)
wuxian:addCompanions("hs__liubei")
wuxian:addCompanions("ol_heg__wuyi")
wuxian:addSkills { "fengsui_heg__guixiang", "fengsui_heg__fumian" }

local xushi = General:new(extension, "fengsui_heg__xushi", "wu", 3, 3, General.Female)
xushi:addSkill("fengsui_heg__fuzhu")
xushi:addSkill("fengsui_heg__chenmeng")

local heqi = General:new(extension, "fengsui_heg__heqi", "wu", 4)
heqi.deputyMaxHpAdjustedValue = -1
heqi:addSkills { "fengsui_heg__junwei", "fengsui_heg__chenji", "fengsui_heg__zhouwang" }

local fengsui_heg__zhangbai = General:new(extension, "fengsui_heg__zhangbai", "wu", 3)
fengsui_heg__zhangbai:addCompanions("ty_heg__luyusheng")
fengsui_heg__zhangbai:addSkill("fengsui_heg__jincai")
fengsui_heg__zhangbai:addSkill("fengsui_heg__lianxi")

local zhanghuai = General:new(extension, "fengsui_heg__zhanghuai", "wu", 3)
zhanghuai.gender = General.Female
zhanghuai:addCompanions("ld__lukang")
zhanghuai:addSkills { "fengsui_heg__laoyan", "fengsui_heg__jueyan" }

-- 吴国武将之后
local xielingyu = General:new(extension, "fengsui_heg__xielingyu", "wu", 3, 3, General.Female)
xielingyu:addSkills { "fengsui_heg__xinyou", "fengsui_heg__yuandi" }

local zhupeilan = General:new(extension, "fengsui_heg__zhupeilan", "wu", 3, 3, General.Female)
zhupeilan:addSkills { "fengsui_heg__tiaomu", "fengsui_heg__kuili" }

local lutan = General:new(extension, "fengsui_heg__lutan", "wu", 3, 3, General.Female)
lutan:addCompanions("ld__lukang")
lutan:addSkills { "fengsui_heg__anliu", "fengsui_heg__kuanqu" }

local gongsunxiu = General:new(extension, "fengsui_heg__gongsunxiu", "qun", 4)
gongsunxiu:addCompanions("ld__gongsunyuan")
gongsunxiu:addSkills { "fengsui_heg__kuizhen", "fengsui_heg__niejiang" }

local yuantan = General:new(extension, "fengsui_heg__yuantan", "qun", 4)
yuantan:addCompanions("hs__yuanshao")
yuantan:addSkills { "fengsui_heg__qiaosi", "fengsui_heg__baizu" }

local fengsui_heg__fuhuanghou = General:new(extension, "fengsui_heg__fuhuanghou", "qun", 3)
fengsui_heg__fuhuanghou.gender = General.Female
fengsui_heg__fuhuanghou:addSkill("fengsui_heg__qujian")
fengsui_heg__fuhuanghou:addSkill("fengsui_heg__weiluan")

local tianchou = General:new(extension, "fengsui_heg__tianchou", "qun", 4)
tianchou:addSkills { "fengsui_heg__shoujie" }

local liufuren = General:new(extension, "fengsui_heg__liufuren", "qun", 3, 3, General.Female)
liufuren:addSkills { "fengsui_heg__dulu", "fengsui_heg__shigong" }

local douwu = General:new(extension, "fengsui_heg__douwudoumiao", "qun", 4, 4, General.Bigender)
douwu:addSkills { "fengsui_heg__bahuan", "fengsui_heg__youhuan" }

local hulie = General:new(extension, "fengsui_heg__hulie", "jin", 4)
hulie:addSkills { "fengsui_heg__kunshi", "fengsui_heg__fudao" }

local zuti = General:new(extension, "fengsui_heg__zuti", "jin", 4)
zuti:addSkills { "fengsui_heg__kangying", "fengsui_heg__jietu" }

local fengsui_heg__wangrong = General:new(extension, "fengsui_heg__wangrong", "jin", 3)
fengsui_heg__wangrong:addCompanions("fengsui_heg__shantao")
fengsui_heg__wangrong:addCompanions("fengsui_heg__hejiao")
fengsui_heg__wangrong:addSkill("fengsui_heg__fumiao")
fengsui_heg__wangrong:addSkill("fengsui_heg__ruwu")

local fengsui_heg__xiejiu = General:new(extension, "fengsui_heg__xiejiu", "jin", 3)
fengsui_heg__xiejiu.gender = General.Female
fengsui_heg__xiejiu:addSkill("fengsui_heg__yuchen")
fengsui_heg__xiejiu:addSkill("fengsui_heg__guitu")

local jiabao = General:new(extension, "fengsui_heg__jiabao", "jin", 3, 3, General.Female)
jiabao:addSkills { "fengsui_heg__gaofan", "fengsui_heg__canyun" }
jiabao:addCompanions("heg__simajiong")

local wangqian = General:new(extension, "fengsui_heg__wangqian", "jin", 3, 3, General.Female)
wangqian:addSkills { "fengsui_heg__yaxi", "fengsui_heg__xiarong" }

local weijie = General:new(extension, "fengsui_heg__weijie", "jin", 3)
weijie:addSkills { "fengsui_heg__shenyu", "fengsui_heg__siji" }

local lemin = General:new(extension, "fengsui_heg__lemin", "jin", 3, 3, General.Female)
lemin:addSkills { "fengsui_heg__juanyi", "fengsui_heg__lishi" }

local shanxia = General:new(extension, "fengsui_heg__shanxia", "jin", 4)
shanxia:addSkills { "fengsui_heg__kuohu", "fengsui_heg__qiongbu" }

local songyi = General:new(extension, "fengsui_heg__songyi", "jin", 3)
songyi:addSkills { "fengsui_heg__qinghuang", "fengsui_heg__pinliu" }

local jin_yueguang = General:new(extension, "fengsui_heg__jinsister", "jin", 3, 3, General.Female)
jin_yueguang:addSkills { "fengsui_heg__jiaosu", "fengsui_heg__yaoming", "fengsui_heg__chuguang" }

local biyu = General:new(extension, "fengsui_heg__biyu", "jin", 4, 4, General.Female)
biyu:addSkills { "fengsui_heg__qusheng", "fengsui_heg__jinshi" }

local xixuan = General:new(extension, "fengsui_heg__xixuan", "jin", 3, 3, General.Female)
xixuan:addSkills { "fengsui_heg__nizi", "fengsui_heg__buge" }

local wangxizhi = General:new(extension, "fengsui_heg__wangxizhi", "jin", 4)
wangxizhi:addSkills { "fengsui_heg__fuyang", "fengsui_heg__zhuiji", "fengsui_heg__tishi" }

local wenqiao = General:new(extension, "fengsui_heg__wenqiao", "jin", 4)
wenqiao:addSkills { "fengsui_heg__shangmu", "fengsui_heg__dunmeng" }

local hejiao = General:new(extension, "fengsui_heg__hejiao", "jin", 3)
hejiao:addSkills { "fengsui_heg__jiezhi", "fengsui_heg__qingsong" }

local yangyan = General:new(extension, "fengsui_heg__yangyan", "jin", 3, 3, General.Female)
yangyan:addCompanions("fengsui_heg__yangzhi")
yangyan:addSkills { "fengsui_heg__xuanbei", "fengsui_heg__jiyuan" }

local yangzhi = General:new(extension, "fengsui_heg__yangzhi", "jin", 3, 3, General.Female)
yangzhi:addCompanions("fengsui_heg__yangyan")
yangzhi:addCompanions("fengsui_heg__yangjun")
yangzhi:addCompanions("heg__yangjun")
yangzhi:addSkills { "fengsui_heg__yisang", "fengsui_heg__jiubo" }

local xuwen = General:new(extension, "fengsui_heg__xuwen", "jin", 3, 3, General.Female)
xuwen:addCompanions("heg__wangjun")
xuwen:addSkills { "fengsui_heg__fuhui", "fengsui_heg__mohua" }

local simayou = General:new(extension, "fengsui_heg__simayou", "jin", 3)
simayou:addSkills { "fengsui_heg__zhenchao", "fengsui_heg__jude" }
simayou:addCompanions("fengsui_heg__jiabao")

local hanmi = General:new(extension, "fengsui_heg__hanmi", "jin", 4)
hanmi.mainMaxHpAdjustedValue = -1
hanmi:addCompanions("fengsui_heg__jiawu")
hanmi:addCompanions("fengsui_heg__hanshou")
hanmi:addSkills { "fengsui_heg__chengtiao", "fengsui_heg__juesi", "fengsui_heg__menyin" }

local jiami = General:new(extension, "fengsui_heg__jiami", "jin", 3)
-- 贾谧是韩谧的变更武将，必须能被 changeHero 正常加载；不作为隐藏武将注册。
jiami.hidden = true
jiami:addCompanions("fengsui_heg__panan")
jiami:addCompanions("fengsui_heg__lujii")
jiami:addSkills { "fengsui_heg__yanyu", "fengsui_heg__duanyuan" }

local zuosi = General:new(extension, "fengsui_heg__zuosizuofen", "jin", 3, 3, General.Bigender)
zuosi:addSkills { "fengsui_heg__yandu", "fengsui_heg__chongjing", "fengsui_heg__aishan" }

local zhanghua = General:new(extension, "fengsui_heg__zhanghua", "jin", 4)
zhanghua.mainMaxHpAdjustedValue = -1
zhanghua.subkingdom = "wei"
zhanghua:addCompanions("heg__yanghu")
zhanghua:addCompanions("ty_heg__yanghu")
zhanghua:addSkills { "fengsui_heg__cangjuan", "fengsui_heg__jianhe", "fengsui_heg__yinbing" }

local shantao = General:new(extension, "fengsui_heg__shantao", "jin", 3)
shantao.subkingdom = "wei"
shantao:addSkills { "fengsui_heg__linzhe", "fengsui_heg__yamai" }

local qiaozhou = General:new(extension, "fengsui_heg__qiaozhou", "jin", 3)
qiaozhou.subkingdom = "shu"
qiaozhou:addCompanions("fengsui_heg__limi", "fengsui_heg__chenshou")
qiaozhou:addSkills { "fengsui_heg__baoguo", "fengsui_heg__yuandao", "fengsui_heg__yunxing" }

local huoyi = General:new(extension, "fengsui_heg__huoyi", "jin", 4)
huoyi.subkingdom = "shu"
huoyi:addSkills { "fengsui_heg__liefa" }

local lujii = General:new(extension, "fengsui_heg__lujii", "jin", 3)
lujii.subkingdom = "wu"
lujii:addCompanions("ld__lukang")
lujii:addSkills { "fengsui_heg__lingzhi", "fengsui_heg__ruluo" }

local zhouchu = General:new(extension, "fengsui_heg__zhouchu", "jin", 4)
zhouchu.subkingdom = "wu"
zhouchu:addSkills { "fengsui_heg__tuanfeng", "fengsui_heg__xuanhe" }

local zhugelian = General:new(extension, "fengsui_heg__zhugelian", "jin", 3, 3, General.Female)
zhugelian:addSkills { "fengsui_heg__chaohua", "fengsui_heg__qiju" }

local peixiu = General:new(extension, "fengsui_heg__peixiu", "jin", 3)
peixiu.subkingdom = "qun"
peixiu:addSkills { "fengsui_heg__juezhi", "fengsui_heg__yunie" }

local zhugejing = General:new(extension, "fengsui_heg__zhugejing", "jin", 4)
zhugejing.subkingdom = "qun"
zhugejing:addSkills { "fengsui_heg__heyi", "fengsui_heg__pijian", "fengsui_heg__zeyu" }

local xunguan = General:new(extension, "fengsui_heg__xunguan", "jin", 4, 4, General.Female)
xunguan:addSkills { "fengsui_heg__cimang", "fengsui_heg__quchi" }

local yangjun = General:new(extension, "fengsui_heg__yangjun", "wild", 4)
yangjun:addCompanions("fengsui_heg__yangzhi", "fengsui_heg__yangyan")
yangjun:addSkills { "fengsui_heg__guishang", "fengsui_heg__aobi" }

-- 夙醒：梦系列的周宣
local dreamzhouxuan = General:new(extension, "fengsui_heg__dream__zhouxuan", "wei", 3)
dreamzhouxuan:addSkills { "fengsui_heg__hanshi", "fengsui_heg__xingji" }

-- Remake 备份也会作为技能骨架加载；校验官方骨架至少完整即可。

-- moved Hebi generals retain their cross-package relations here.
zhugelian.subkingdom = "wu"
xunguan.subkingdom = "qun"
liufuren:addCompanions("hs__yuanshao")
wangqian:addCompanions("fengsui_heg__weijie")
weijie:addCompanions("fengsui_heg__wangqian")
xixuan:addCompanions("fengsui_heg__wangxizhi")
zhugelian:addCompanions("heg__simazhou")
wangxizhi:addCompanions("fengsui_heg__xixuan")
lemin:addCompanions("heg__simaying")
biyu:addCompanions("heg__simaliang")

assert(#extension.skill_skels >= 24, "fengsui_liwu must load the official skill skeletons")


Fk:loadTranslationTable{
  ["fengsui_heg__zhouxuan"] = "周宣",
  ["#fengsui_heg__zhouxuan"] = "醒踌者",
  ["designer:fengsui_heg__zhouxuan"] = "公冶长风",
  ["illustrator:fengsui_heg__zhouxuan"] = "公冶长风",
  ["cv:fengsui_heg__zhouxuan"] = "暂无",
  ["fengsui_heg__wumei"] = "寤寐",
  [":fengsui_heg__wumei"] = "当你明置或暗置此武将牌时，你摸两张牌且可以视为使用一张<a href=':tricky_heist'>【巧取豪夺】</a>，然后若你因此获得奇珍牌，你本回合使用牌无次数限制。",
  ["#fengsui_heg__wumei"] = "寤寐：你可以视为使用【巧取豪夺】",
  ["fengsui_heg__jiemeng"] = "解梦",
  [":fengsui_heg__jiemeng"] = "当你受到伤害后，你可以视为对一名确定势力的角色使用一张<a href=':overbearing'>【咄咄逼人】</a>，若其因此受到伤害且你武将牌均明置，你暗置此武将牌。",
  ["#fengsui_heg__jiemeng"] = "解梦：你可以视为对一名确定势力的角色使用【咄咄逼人】",
    ["$fengsui_heg__wumei1"] = "大梦落雪三千丈，可将暮鸿筑玉京。",
      ["$fengsui_heg__wumei2"] = "雪者水之形也，冰者雪之骨也，其态左而其质右。",
  ["$fengsui_heg__wumei3"] = "梦中所见，皆是心中未平之事。",
  ["$fengsui_heg__wumei4"] = "一枕黄粱未醒，且看风雪换人间。",
          ["$fengsui_heg__jiemeng1"] = "暮雪纷飞，寒气盈野，煨红泥火炉，饮新醅绿蚁。",
      ["$fengsui_heg__jiemeng2"] = "骚客履薄冰，不知梦外落雪、梦中霜寒。",
  ["$fengsui_heg__jiemeng3"] = "梦可解，局难解，唯以此身试之。",
  ["$fengsui_heg__jiemeng4"] = "若问吉凶，且看今夜谁先惊醒。",
  ["~fengsui_heg__zhouxuan"] = "雪漫青山处，不见夜归人。",
}


Fk:loadTranslationTable{
  ["fengsui_heg__chenshou"] = "陈寿",
  ["#fengsui_heg__chenshou"] = "犁山者",
  ["designer:fengsui_heg__chenshou"] = "公冶长风",
  ["illustrator:fengsui_heg__chenshou"] = "公冶长风",
  ["cv:fengsui_heg__chenshou"] = "暂无",
  ["fengsui_heg__dianmo"] = "点墨",
  [":fengsui_heg__dianmo"] = "你可以将一张红色/黑色装备牌当【无懈可击】/<a href=':rob__jink'>【掠闪】</a>使用；当你使用奇珍牌后，你可以与一名装备区牌数量小于你的角色交换装备区的所有牌。",
  ["#fengsui_heg__dianmo-use"] = "点墨：你可以将一张装备牌当【无懈可击】或【掠闪】使用",
  ["#fengsui_heg__dianmo-swap"] = "点墨：你可以与一名装备区牌数较少的角色交换装备区的所有牌",
  ["fengsui_heg__fuzai"] = "覆载",
  ["fengsui_heg__fuzaiRemake"] = "覆载·改",
  [":fengsui_heg__fuzai"] = "锁定技，若你未装备宝物，你视为装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>。当其他角色装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>后，你需弃置装备区所有牌并变更副将。",
  [":fengsui_heg__fuzaiRemake"] = "锁定技，若你未装备宝物，你视为装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>。当其他角色装备<a href=':nine_tripod_cauldrons'>【九州鼎】</a>后，你需选择一项：1.弃置装备区所有牌并变更副将；2.视为使用一张<a href=':part_ways'>【分道扬镳】</a>。",
  ["fengsui_heg__fuzai_discard"] = "弃置装备区所有牌并变更副将",
  ["fengsui_heg__fuzai_partways"] = "视为使用【分道扬镳】",
  ["$fengsui_heg__dianmo1"] = "秉笔直书，善恶自有后世评说。",
  ["$fengsui_heg__dianmo2"] = "一字落简，便存兴亡之实。",
  ["$fengsui_heg__dianmo3"] = "史家之墨，不为尊者讳。",
  ["$fengsui_heg__dianmo4"] = "旧闻互异，当参校而定其真。",
  ["$fengsui_heg__fuzai1"] = "九州之重，当载于信史之中。",
  ["$fengsui_heg__fuzai2"] = "国有兴替，典册不可随之湮没。",
  ["$fengsui_heg__fuzai3"] = "承前人之遗事，启后世之明鉴。",
  ["$fengsui_heg__fuzai4"] = "覆载万象，方成一家之言。",
  ["~fengsui_heg__chenshou"] = "著述未竟，唯愿后人续之……",
}


Fk:loadTranslationTable{
  ["fengsui_heg__sunyuan"] = "孙鸢",
  ["#fengsui_heg__sunyuan"] = "履尘者",
  ["designer:fengsui_heg__sunyuan"] = "公冶长风",
  ["illustrator:fengsui_heg__sunyuan"] = "公冶长风",
  ["cv:fengsui_heg__sunyuan"] = "暂无",
  ["fengsui_heg__dongxin"] = "恫心",
  [":fengsui_heg__dongxin"] = "当你受到或造成伤害后，你可以视为对伤害来源或目标使用一张<a href=':reveal_intention'>【图穷匕见】</a>并与其各摸一张牌，然后你可重铸至多等同于此次伤害值张牌并使用其中的【杀】（不计入次数）。",
  ["#fengsui_heg__dongxin-discard"] = "恫心：你可以重铸至多等同于此次伤害值张牌，并依次使用其中的【杀】",
  ["#fengsui_heg__dongxin-use"] = "恫心：你可以使用弃牌堆中的此【杀】",
    ["$fengsui_heg__dongxin1"] = "三军胆裂非因剑，一念慑魂自威仪！",
  ["$fengsui_heg__dongxin2"] = "战鼓未擂心先乱，何不卸甲拜红妆？",
  ["$fengsui_heg__dongxin3"] = "心胆俱寒，便是千军也自溃。",
  ["$fengsui_heg__dongxin4"] = "恫心夺志，破阵只在一念之间。",
  ["~fengsui_heg__sunyuan"] = "此月曾照闺中……",
}


Fk:loadTranslationTable{
  ["fengsui_heg__liuhui"] = "刘徽",
  ["#fengsui_heg__liuhui"] = "精算者",
  ["designer:fengsui_heg__liuhui"] = "公冶长风",
  ["illustrator:fengsui_heg__liuhui"] = "公冶长风",
  ["cv:fengsui_heg__liuhui"] = "暂无",
  ["fengsui_heg__jieshu"] = "解术",
  [":fengsui_heg__jieshu"] = "当你于回合内使用牌指定目标后，你可视为使用一张与原牌合法目标相同的普通锦囊牌，然后此技能失效直至你使用奇珍牌或一张与此牌合法目标相同的实体牌。",
  ["#fengsui_heg__jieshu"] = "解术：你可以使用一张与原牌合法目标相同的普通锦囊牌",
  ["@fengsui_heg__jieshu"] = "解术失效",
  ["@fengsui_heg__jieshu_name"] = "解术·",
      ["$fengsui_heg__jieshu1"] = "累乘除以成九数者，可以加减解之。",
    ["$fengsui_heg__jieshu2"] = "数有其理，见筹一可知沙数。",
  ["$fengsui_heg__jieshu3"] = "万法虽繁，皆可归于一算。",
  ["$fengsui_heg__jieshu4"] = "以术破术，方知变化无穷。",
  ["~fengsui_heg__liuhui"] = "算学如海，穷我一生，只得杯水。",
}


Fk:loadTranslationTable{
  ["fengsui_heg__wanghuifeng"] = "王惠风",
  ["#fengsui_heg__wanghuifeng"] = "戮时者",
  ["designer:fengsui_heg__wanghuifeng"] = "公冶长风",
  ["illustrator:fengsui_heg__wanghuifeng"] = "公冶长风",
  ["cv:fengsui_heg__wanghuifeng"] = "暂无",
  ["fengsui_heg__dilie"] = "砥烈",
  [":fengsui_heg__dilie"] = "当你造成伤害后，你可以重铸任意张非基本牌；当你受到伤害后，若你的武器栏没有牌，你可以随机将弃牌堆中的一张奇珍牌或伤害来源装备区的一张牌置入你的对应装备栏，若此牌为武器牌，你可以对伤害来源造成1点伤害。",
  ["#fengsui_heg__dilie-recast"] = "砥烈：你可以重铸任意张非基本牌",
  ["#fengsui_heg__dilie-choice"] = "砥烈：选择随机置入对应装备栏的牌的来源",
  ["fengsui_heg__dilie_curio"] = "弃牌堆中的奇珍牌",
  ["fengsui_heg__dilie_source_equip"] = "伤害来源装备区的牌",
  ["#fengsui_heg__dilie-damage"] = "砥烈：是否对 %dest 造成1点伤害？",
  ["$fengsui_heg__dilie1"] = "烈节在心，岂因危迫而改！",
  ["$fengsui_heg__dilie2"] = "宁折此身，不坠家门清望。",
  ["$fengsui_heg__dilie3"] = "刀兵虽厉，难夺我守志之心。",
  ["$fengsui_heg__dilie4"] = "我皇太子妇，司徒公之女，胡羌小丑，敢欲干我乎？",
  ["~fengsui_heg__wanghuifeng"] = "宗族倾覆，妾亦不独生……",
}

Fk:appendKingdomMap("fengsui_neutral_old", { "wei", "shu", "wu", "qun", "jin" })
Fk:appendKingdomMap("fengsui_neutral", { "wei", "shu", "wu", "qun", "jin" })
require("packages.fengsui.pkg.fengsui_liwu.liwu_neutral_compat").install()










assert(#extension.generals == 60, "fengsui_liwu must register exactly 60 generals")
require "packages.fengsui.pkg.fengsui_liwu.option_translations"

return extension
