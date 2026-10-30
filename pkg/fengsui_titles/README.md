# fengsui_titles · 自用称号包

独立二创包，不影响官方 `player_titles`。当前包含十八条私人称号（含八条动态「动·」系列）：

| 稳定ID | 称号文字 | 样式 | 来源 |
| --- | --- | --- | --- |
| `satenruiko` | 佐天泪子 | `fengsui_titles.satenruiko` | 用户抠好的透明横幅 `images/saten_banner.png`（2152x731 RGBA，原字节保留） |
| `rainbowfamily` | 彩虹家族 | `fengsui_titles.rainbowfamily` | `images/rainbow_banner.png`（2170x725 RGBA，原字节保留） |
| `dreamingsaint` | 大梦仙尊 | `fengsui_titles.dreamingsaint` | `images/dream_banner.png`（2172x724 RGBA，原字节保留） |
| `bigdreamingsaint` | 极大梦仙尊 | `fengsui_titles.bigdreamingsaint` | 动态版由 `images/bigdream_atlas.png`（36 帧斜向流光图集，6×6 网格 440×120）+ `bigdream_poster.png` 组成（霓虹仙侠秘境底图 bigdream_banner），循环 2.4s、`zoom` 0.9 |
| `shiningrainbowfamily` | 闪光彩虹家族 | `fengsui_titles.shiningrainbowfamily` | 动态版由 `images/shiningrainbow_atlas.png`（48 帧星星闪烁图集，6×8 网格 440×138）+ `shiningrainbow_poster.png` 组成（独角兽底图），循环 3.0s、显示宽度 96、`zoom` 0.9 |
| `misakamikoto` | 御坂美琴 | `fengsui_titles.misakamikoto` | `images/misaka_banner.png`（1916x821 RGBA，原字节保留） |
| `dynsatenruiko` | 动·佐天泪子 | `fengsui_titles.dynsatenruiko` | `images/saten_banner.png`（2152x731 RGBA，原字节保留）；动态版由 `images/dynsaten_atlas.png`（36 帧「水流环绕四周 + 花瓣飘落中间」图集）+ `dynsaten_poster.png` 组成 |
| `dynmisakamikoto` | 动·御坂美琴 | `fengsui_titles.dynmisakamikoto` | `images/misaka_banner.png`（1916x821 RGBA，原字节保留）；动态版由 `images/dynmisaka_atlas.png`（36 帧电流闪电图集）+ `dynmisaka_poster.png` 组成 |
| `dyndreamingsaint` | 动·大梦仙尊 | `fengsui_titles.dyndreamingsaint` | `images/dream_banner.png`（2172x724 RGBA，原字节保留）；动态版由 `images/dream_dynamic_atlas.png`（36 帧金白流光图集，6×6 网格 440×120）+ `dream_dynamic_poster.png` 组成，循环 2.6s、`zoom` 0.9 |
| `dynrainbowfamily` | 动·彩虹家族 | `fengsui_titles.dynrainbowfamily` | `images/rainbow_banner.png`（2170x725 RGBA，原字节保留）；动态版由 `images/rainbow_dynamic_atlas.png`（36 帧彩虹流光图集，6×6 网格 440×120）+ `rainbow_dynamic_poster.png` 组成，循环 3.0s、`zoom` 0.9 |
| `qingmengguichen` | 情梦归尘 | `fengsui_titles.qingmengguichen` | `images/qingmeng_banner.png`（2172x724 RGBA，原字节保留，紫金水墨风） |
| `qiexianglang` | 窃香郎 | `fengsui_titles.qiexianglang` | `images/qiexiang_banner.png`（2167x726 RGBA，原字节保留，紫金水墨风） |
| `dynqingmengguichen` | 动·情梦归尘 | `fengsui_titles.dynqingmengguichen` | `images/qingmeng_banner.png`（2172x724 RGBA，原字节保留）；动态版由 `images/dynqingmeng_atlas.png`（36 帧「金线流光（对角）+ 紫金花瓣飘落」图集，6×6 网格 440×120）+ `dynqingmeng_poster.png` 组成，循环 2.8s、`zoom` 0.9 |
| `dynqiexianglang` | 动·窃香郎 | `fengsui_titles.dynqiexianglang` | `images/qiexiang_banner.png`（2167x726 RGBA，原字节保留）；动态版由 `images/dynqiexiang_atlas.png`（36 帧「暖金光晕（茶盏/香炉）+ 细碎金粉上浮」图集，6×6 网格 440×120）+ `dynqiexiang_poster.png` 组成，循环 3.0s、`zoom` 0.9 |
| `hongzhilingkong` | 鸿志凌空 | `fengsui_titles.hongzhilingkong` | `images/hongzhi3_banner.png`（2143x734 RGBA，原字节保留，墨卷云山版）；`zoom` 0.9 框内略缩小留边 |
| `dynhongzhilingkong` | 动·鸿志凌空 | `fengsui_titles.dynhongzhilingkong` | `images/hongzhi3_banner.png`（2143x734 RGBA，原字节保留）；动态版由 `images/dynhongzhi_atlas.png`（36 帧「水墨晕染」图集，6×6 网格 440×120）+ `dynhongzhi_poster.png` 组成，循环 3.0s、`zoom` 0.9 |
| `qingkui` | 青魁幽梦 | `fengsui_titles.qingkui` | `images/qingkui_banner.png`（1920x640 RGBA，由用户剪贴板 JPG 边缘泛洪抠白底转透明，内部白云/月亮保留，alpha 边缘 0.8px 羽化）；静态版，`cropBias` 0.4、`zoom` 0.9 |
| `dynqingkui` | 动·青魁幽梦 | `fengsui_titles.dynqingkui` | 同 `qingkui_banner.png`；翡翠流光+金粉上浮版（QML 程序化动画，无图集）：画面本体静止；三团青绿软雾（RadialGradient）原地明灭+缓慢漂移 + 15° 翡翠细光带（0.24 框宽）6.5s 匀速单向扫过（歇 1.2s，显式 from 修复循环重启）+ 12 粒金粉自底部错峰上浮渐隐（2.8~3.8s/粒，#f2d98c/#ffe9b8），`motionEnabled`=false 时静止 |

显示方式：四个组件设计尺寸均与统一显示框一致（110x30），横幅按宽度铺满整框，
垂直方向利用透明留边吸收溢出，各组件用 `cropBias` 微调裁切位置：

- 佐天泪子 0.106：实际内容上下各裁约 1.4px（<5%）。
- 彩虹家族 0.545：上下裁切均衡，实际内容约裁 7%。
- 大梦仙尊 0.4125：实际内容约裁 3.4%。
- 极大梦仙尊 0.55：动态版取景窗口（霓虹仙侠秘境 bigdream_banner），斜向流光，显示缩放 zoom 0.9（框内略缩小留边）。
- 闪光彩虹家族 0.68：动态版取景窗口（独角兽底图），星星闪烁，显示宽度 96、zoom 0.9。
- 动·大梦仙尊 0.4125：动态版取景窗口（原大梦底图 dream_banner），金白流光，zoom 0.9。
- 动·彩虹家族 0.545：动态版取景窗口（原彩虹底图 rainbow_banner），彩虹流光，zoom 0.9。
- 动·佐天泪子 0.106：满框基本全图，与静态佐天泪子取景一致，zoom 0.9。
- 动·御坂美琴 0.25：与静态御坂美琴取景一致（原图比例偏方 2.38，保脸/拳/字），zoom 0.9。
- 御坂美琴 0.25：原图内容比例偏方（2.38），铺满需垂直裁约 36%，
  取偏上位置保住角色脸部、拳头与完整文字，只裁上下电光特效。
- 情梦归尘 0.40：铺满需垂直裁约 18%，取景偏上（保脸部与「情梦归尘」文字完整，用户最终选 0.4）。
- 窃香郎 0.55：铺满需垂直裁约 19%，取景居中略偏下（保脸部、茶盏与「窃香郎」文字完整，用户最终选 0.55）。
- 动·情梦归尘 0.40：动态版取景窗口与静态情梦归尘一致（bias 0.40），金线流光 + 紫金花瓣，zoom 0.9。
- 动·窃香郎 0.55：动态版取景窗口与静态窃香郎一致（bias 0.55），暖金光晕 + 金粉上浮，zoom 0.9。
- 鸿志凌空 0.6（定稿）：用 **v3 墨卷云山**底图（2143x734，内容比 2.92，竖裁仅约 20%），`zoom` 0.9，`cropBias` 用户最终选 **0.6**（保住人物、大字与右侧落日，略带上方的云）。v1(水墨展卷)/v2(墨韵华章) 原图仍留 images/ 备份。
- 动·鸿志凌空 0.6：动态版取景窗口与静态鸿志凌空一致（v3 + bias 0.6），水墨晕染（墨团晕开 + 飞白墨点），zoom 0.9。

透明背景在浅色/深色界面都干净。服务器设置其他名称时显示配套配色的
纯文本回退，不会用图片内固定原名覆盖服务器文字。

## 安装与发放

1. 客户端：确认本包位于 `packages/fengsui/pkg/fengsui_titles/`，重启客户端加载样式。
2. 服务端：把整个 `fengsui_titles` 目录放进服务器已加载的扩展包目录，控制台执行：

```text
title load fengsui_titles
title grant satenruiko 玩家账号
title grant rainbowfamily 玩家账号
title grant dreamingsaint 玩家账号
title grant bigdreamingsaint 玩家账号
title grant misakamikoto 玩家账号
title grant dynsatenruiko 玩家账号
title grant dynmisakamikoto 玩家账号
title grant dyndreamingsaint 玩家账号
title grant dynrainbowfamily 玩家账号
title grant qingmengguichen 玩家账号
title grant qiexianglang 玩家账号
title grant dynqingmengguichen 玩家账号
title grant dynqiexianglang 玩家账号
title grant hongzhilingkong 玩家账号
title grant dynhongzhilingkong 玩家账号
title show 玩家账号
```

发放后玩家在个人信息中自行装备。改清单后执行 `title reload` 即可，无需重启。

## 注意事项

- 各 ID 为稳定ID，不要随文字或门槛变化而修改，改了会被视为另一个称号。
- 底图未做压缩（四张共约 9.3 MiB）；如需减小客户端体积，可另存压缩版后改
  对应 `qml/*Title.qml` 的 `source`，显示效果不受影响。
- **极大梦仙尊为动态称号**：现由 `images/bigdream_atlas.png`（36 帧「斜向流光横扫」图集，6×6 网格、每格 440×120）驱动，
  取景来自霓虹仙侠秘境底图 bigdream_banner（bias 0.55）；模仿官方双阴糕手的 `NumberAnimation` + `Canvas` 逐帧切格做法；
  `motionEnabled` 关闭或图集未就绪时回退到静态海报，服务器设置其他名称时回退到纯文本。循环周期 2.4 秒。
- **闪光彩虹家族为动态称号**：现由 `images/shiningrainbow_atlas.png`（48 帧「星星闪烁」图集，6×8 网格、每格 440×138）驱动，
  取景来自独角兽底图（bias 0.68）；循环周期 3.0 秒，显示宽度 96、`zoom` 0.9。
- **动·佐天泪子为动态称号**：`images/dynsaten_atlas.png`（36 帧「水流环绕四周 + 花瓣飘落中间」图集，6×6 网格、每格 440×120），
  边框青蓝流光巡回、中部粉白花瓣飘落；循环周期 2.8 秒、`zoom` 0.9。
- **动·御坂美琴为动态称号**：`images/dynmisaka_atlas.png`（36 帧「电流闪光」图集，6×6 网格、每格 440×120），
  每帧随机蓝白电弧（带辉光）沿画面窜动并叠加全屏蓝色脉冲，与源图电光轨道炮呼应；循环周期 1.6 秒（更急促）、`zoom` 0.9。
- **动·大梦仙尊为动态称号**：`images/dream_dynamic_atlas.png`（36 帧「金白流光横扫」图集，6×6 网格、每格 440×120），
  取景来自原版大梦底图 dream_banner（bias 0.4125）；循环周期 2.6 秒、`zoom` 0.9。与极大梦仙尊（霓虹仙侠秘境 + 斜向流光）底图与取景均不同，互不重复。
- **动·彩虹家族为动态称号**：`images/rainbow_dynamic_atlas.png`（36 帧「彩虹流光横扫」图集，6×6 网格、每格 440×120），
  取景来自原版彩虹底图 rainbow_banner（bias 0.545）；循环周期 3.0 秒、`zoom` 0.9。与闪光彩虹家族（独角兽 + 星星闪烁）底图与特效均不同，互不重复。
- **动·情梦归尘为动态称号**：`images/dynqingmeng_atlas.png`（36 帧「金线流光（对角）+ 紫金花瓣飘落」图集，6×6 网格、每格 440×120），
  对角金色流光扫过 + 数片紫金花瓣飘落，与紫金水墨底图呼应；取景来自情梦归尘底图 qingmeng_banner（bias 0.40）；循环周期 2.8 秒、`zoom` 0.9。
- **动·窃香郎为动态称号**：`images/dynqiexiang_atlas.png`（36 帧「暖金光晕（茶盏/香炉）+ 细碎金粉上浮」图集，6×6 网格、每格 440×120），
  暖金色光晕自茶盏/香炉处脉动弥散、细碎金粉自下上浮；取景来自窃香郎底图 qiexiang_banner（bias 0.55）；循环周期 3.0 秒、`zoom` 0.9。
- **动·鸿志凌空为动态称号**：`images/dynhongzhi_atlas.png`（36 帧「水墨晕染」图集，6×6 网格、每格 440×120），
  **一笔毛笔**：自左上**落笔**（顿点）→ 行笔沿贝塞尔弧线**斜扫至右下**→ 收笔**收成尖锋（笔锋）**；
  笔身是有形有边的实心墨（不再是软雾），带**飞白断口**，并沿边缘有一道亮勾边以便在暗底上显形；
  笔迹中途下压**正好越过人物**（人物位于 x≈105-130）。整笔扫完后淡出，一个循环一次完整起笔。
  另配**祥云纹**（柔和云头 + 金线卷曲云尾，2 朵缓慢漂移）与**浮金**（10 粒金屑上浮明灭）。
  取景来自鸿志凌空底图 hongzhi3_banner（v3 墨卷云山，bias 0.6）；循环周期 3.0 秒、`zoom` 0.9。与现有动·佐天(水流+花瓣)/动·御坂(电流)/动·大梦(金白流光)/动·彩虹(彩虹流光)/动·情梦(金线+花瓣)/动·窃香(金晕+金粉) 特效均不重复。
- 想换成美术做的真动画：把动画导出为「定宽等高、横向排成网格的 PNG 图集」覆盖对应 `*_atlas.png`，
  并把对应 `qml/*.qml` 里的 `frameCount`、`index % 6` 与 `Math.floor(index / 6)` 的列数、每行像素高度（均为 120）、以及 `duration` 改成对应值即可，
  无需改动清单或样式。
