// 烽燧燎原 · 酣世额外回合 · 梦泽仙气（蓝色主体）+ 梦境 BGM
// 由 skills/fengsui_effect_hanshi_aura.lua 通过 doSuperLightBox 调用：
//   loadData({ running = true })   起雾（淡入，之后常驻；同时 BGM 淡入循环）
//   loadData({ running = false })  散雾（淡出后 finish；BGM 淡出停止，游戏 BGM 复原）
//
// 设计约束（改动前先读）：
//   1. 全部图形由 Canvas 程序化绘制，不依赖任何图片素材；唯一外部资源是
//      audio/BGM/dream_hanshi.mp3，删掉它与本文件即无残留。
//   2. 纯氛围层：enabled: false，不拦截鼠标，出牌与选择照常穿透。
//   3. 收尾统一走 finish()，并校验 item === root，避免覆盖后到的新特效。
//   4. 与悼离的 RainPhase 同一套生命周期：BGM 不用 Backend.playSound（只能播一次性
//      文件），而是 MediaPlayer + loops: Infinite 自己循环、自己停；服务端只发
//      「开始 / 结束」两条指令，不产生任何 yield。
//   5. 音源已做无缝循环与电平归一化（见文件清单注释），换素材必须重做这两步：
//      首尾交叉淡化 4 s，否则循环接缝会「咔」一下；电平对齐到 mean ≈ -20.7 dB，
//      与游戏 BGM（mean -17.5 dB）同一档位，再靠 baseVolume 压到其下方。
//
// 为什么 import Fk：Cpp.volume() 与 Config.bgmVolume 都由 Fk 模块提供，缺这行
// 两者都是 undefined，结果是有画面但完全没声音（RainPhase 踩过同一个坑）。
// 音频路径仍用 Qt.resolvedUrl 相对本文件解析，不依赖 Cpp.path——包放在应用目录
// 或用户目录都能定位。

import QtQuick
import QtMultimedia
import Fk

Item {
  id: root
  anchors.fill: parent
  enabled: false // 纯氛围层，不拦截任何鼠标事件

  property bool running: false
  property bool everStarted: false
  property real intensity: 0
  property real clock: 0
  property var motes: []

  // ── 音频 ────────────────────────────────────────────────
  // bgmBase 是「床」的衰减：母带已归一化，这里只负责把它放到游戏 BGM 之下。
  // 默认效果音量 50 → 0.5 × 0.55 ≈ 0.275（-11 dB），约比游戏 BGM 低 11 dB，
  // 是「能听出旋律但不抢牌局」的位置。嫌轻就抬 bgmBase，不要改音频文件。
  readonly property bool bgmOn: true          // 想静音只改这一行，画面不受影响
  readonly property real bgmBase: 0.55
  readonly property url bgmPath: Qt.resolvedUrl("../../audio/BGM/dream_hanshi.mp3")

  // 梦境 BGM 与对局 BGM 同时响会糊成一片，所以进场时把游戏 BGM 临时压到 32%，
  // 散雾时原样还回去。这是本地客户端行为（Config 是 QML 单例，只影响自己）。
  // 3 个注意点：
  //   ① 只记录进场那一刻的值，恢复时写回原值，不做叠加，重复进场也不会越压越低；
  //   ② 记录值存在 bgmKeep，用 bgmDucked 做幂等，组件被销毁时也要能还原；
  //   ③ 玩家若正好在特效期间改设置，以他的新值为准会被这里覆盖一次——概率极低，
  //      且在设置里再动一下滑块即可，不影响存档（Config 只在 saveConf 时落盘）。
  readonly property bool duckGameBgm: true
  readonly property real duckRatio: 0.32
  property bool bgmDucked: false
  property real bgmKeep: -1

  // 三圈环绕的仙气：r 为半径（相对画面短边），squash 压扁成透视椭圆，
  // speed 为角速度（度/秒），方向有正有负才像气流互相缠绕。
  property var rings: [
    { r: 0.19, squash: 0.30, angle: 0, speed: 11, w: 2.4, alpha: 0.34 },
    { r: 0.27, squash: 0.36, angle: 60, speed: -7, w: 1.6, alpha: 0.26 },
    { r: 0.36, squash: 0.42, angle: 130, speed: 5, w: 3.2, alpha: 0.18 }
  ]

  readonly property int tickMs: 16
  readonly property int moteCount: 84

  function finish() {
    if (roomScene && roomScene.bigAnim && roomScene.bigAnim.item === root) {
      roomScene.bigAnim.source = "";
    }
  }

  // 玩家效果音量 × 本层基准；读不到就当满音量（宁可响一点，也不要莫名静音）
  function effectGain() {
    var v = 100;
    try { v = Cpp.volume(); } catch (e) { v = 100; }
    if (typeof v !== "number" || isNaN(v)) v = 100;
    return Math.max(0, Math.min(1, v / 100)) * root.bgmBase;
  }

  function duckBgm() {
    if (!root.bgmOn || !root.duckGameBgm || root.bgmDucked) return;
    try {
      var cur = Config.bgmVolume;
      if (typeof cur !== "number" || isNaN(cur) || cur <= 0) return; // 玩家本来就关了 BGM
      root.bgmKeep = cur;
      root.bgmDucked = true;
      Config.bgmVolume = cur * root.duckRatio;
    } catch (e) {
      console.warn("[fengsui_effect] duck bgm skipped:", e);
    }
  }

  function restoreBgm() {
    if (!root.bgmDucked) return;
    root.bgmDucked = false;
    try {
      if (root.bgmKeep >= 0) Config.bgmVolume = root.bgmKeep;
    } catch (e) {
      console.warn("[fengsui_effect] restore bgm failed:", e);
    }
    root.bgmKeep = -1;
  }

  function rand(a, b) {
    return a + Math.random() * (b - a);
  }

  function respawnMote(m, atBottom) {
    var w = root.width > 0 ? root.width : 1280;
    var h = root.height > 0 ? root.height : 720;
    m.x = Math.random() * w;
    m.y = atBottom ? h + rand(10, 120) : Math.random() * h;
    m.rad = rand(1.1, 3.6);
    m.vy = rand(14, 42);          // 上升速度
    m.amp = rand(6, 26);          // 左右摆幅
    m.ph = Math.random() * Math.PI * 2;
    m.freq = rand(0.5, 1.35);
    m.a = rand(0.22, 0.62);
    m.warm = Math.random() < 0.22; // 少量偏青白，避免整片纯蓝发闷
    return m;
  }

  function makeMotes() {
    var arr = [];
    for (var i = 0; i < root.moteCount; i++) {
      arr.push(root.respawnMote({}, false));
    }
    return arr;
  }

  // 画面与声音一起进场：雾 0.9 s 淡入，音乐 1.6 s 淡入（比画面慢半拍，
  // 听起来像「雾先起、乐随后来」，直接硬起会显得突兀）。
  ParallelAnimation {
    id: startSeq
    NumberAnimation {
      target: root
      property: "intensity"
      to: 1
      duration: 900
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      id: bgmFadeIn
      target: bgmOut
      property: "volume"
      to: 0
      duration: 1600
      easing.type: Easing.OutCubic
    }
    ScriptAction {
      script: {
        if (!root.bgmOn) return;
        if (dreamBgm.playbackState !== MediaPlayer.PlayingState) dreamBgm.play();
      }
    }
  }

  // 散场：雾 0.7 s 散去，音乐 1.1 s 淡出后再停，避免尾音被硬切。
  SequentialAnimation {
    id: stopSeq
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "intensity"
        to: 0
        duration: 700
        easing.type: Easing.InCubic
      }
      NumberAnimation {
        target: bgmOut
        property: "volume"
        to: 0
        duration: 1100
        easing.type: Easing.InCubic
      }
    }
    ScriptAction {
      script: {
        dreamBgm.stop();
        root.restoreBgm();
        root.finish();
      }
    }
  }

  function start() {
    if (root.running) return;
    root.running = true;
    root.everStarted = true;
    root.duckBgm();
    stopSeq.stop();
    // to 必须在这里现算：Cpp.volume() 是函数调用，不是可绑定的属性，
    // 写在动画里只会在构造时算一次，玩家改过音量后就不跟手了。
    bgmFadeIn.to = root.bgmOn ? root.effectGain() : 0;
    startSeq.restart();
  }

  function loadData(d) {
    d = d || {};
    if (d.running === false) {
      // 还没真正亮起来就被叫停（常见于新造的 item），直接收尾，避免闪一下。
      if (!root.everStarted || root.intensity < 0.02) {
        dreamBgm.stop();
        root.restoreBgm();
        root.finish();
        return;
      }
      root.running = false;
      startSeq.stop();
      stopSeq.restart();
    } else {
      root.start();
    }
  }

  Component.onCompleted: {
    root.motes = root.makeMotes();
    root.start();
  }

  Component.onDestruction: {
    // 被别的特效顶掉时 item 会被销毁，务必在这里停声并还原游戏 BGM，
    // 否则音乐会一直挂在后台、BGM 音量也停在压低值。
    dreamBgm.stop();
    root.restoreBgm();
  }

  // ── 梦境 BGM：循环播放，音量淡入淡出 ──────────────────────────
  MediaPlayer {
    id: dreamBgm
    source: root.bgmPath
    loops: MediaPlayer.Infinite
    audioOutput: AudioOutput {
      id: bgmOut
      volume: 0
    }
    onPlaybackStateChanged: {
      // loops: Infinite 正常不会走到 Stopped；这里只防多轨设备切换等意外中断
      if (root.running && playbackState === MediaPlayer.StoppedState) {
        play();
      }
    }
    onErrorOccurred: function (error, errorString) {
      console.warn("[fengsui_effect] dream bgm failed:", error, errorString, root.bgmPath);
    }
  }

  // ── 底色：极轻的靛蓝，只压一点亮度，不遮牌面 ──────────────────
  Rectangle {
    anchors.fill: parent
    color: "#0B1B33"
    opacity: root.intensity * 0.10
  }

  Canvas {
    id: auraCanvas
    anchors.fill: parent
    opacity: root.intensity

    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();

      var w = width;
      var h = height;
      if (w <= 0 || h <= 0) return;

      var cx = w * 0.5;
      var cy = h * 0.52;
      var R = Math.min(w, h);
      // 呼吸：0.86~1.0，慢速，别让人眼觉得在闪
      var b = 0.86 + 0.14 * Math.sin(root.clock * 1.15);

      // 1) 中心仙雾：径向渐变，蓝色主体，边缘完全透明
      var g = ctx.createRadialGradient(cx, cy, R * 0.03, cx, cy, R * 0.82);
      g.addColorStop(0.00, "rgba(176,224,255," + (0.20 * b).toFixed(3) + ")");
      g.addColorStop(0.30, "rgba(116,182,255," + (0.13 * b).toFixed(3) + ")");
      g.addColorStop(0.62, "rgba(64,124,214," + (0.07 * b).toFixed(3) + ")");
      g.addColorStop(1.00, "rgba(24,56,120,0)");
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, w, h);

      // 2) 环绕光环：透视椭圆，缓慢自转，透明度各自呼吸
      for (var i = 0; i < root.rings.length; i++) {
        var rg = root.rings[i];
        var ra = rg.alpha * b * (0.72 + 0.28 * Math.sin(root.clock * 1.6 + i * 1.1));
        ctx.save();
        ctx.translate(cx, cy);
        ctx.rotate(rg.angle * Math.PI / 180);
        ctx.scale(1, rg.squash);
        ctx.strokeStyle = "rgba(150,208,255," + ra.toFixed(3) + ")";
        ctx.lineWidth = rg.w;
        ctx.beginPath();
        ctx.arc(0, 0, R * rg.r, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
      }

      // 3) 浮游光点：向上飘 + 横向摆动 + 明暗闪烁
      var arr = root.motes;
      for (var j = 0; j < arr.length; j++) {
        var m = arr[j];
        var px = m.x + Math.sin(root.clock * m.freq + m.ph) * m.amp;
        var py = m.y;
        var tw = 0.55 + 0.45 * Math.sin(root.clock * 2.6 + m.ph * 1.7);
        var al = m.a * tw * b;
        if (al <= 0.01) continue;

        // 外层柔光
        ctx.beginPath();
        ctx.fillStyle = m.warm
          ? "rgba(196,240,255," + (al * 0.26).toFixed(3) + ")"
          : "rgba(128,196,255," + (al * 0.30).toFixed(3) + ")";
        ctx.arc(px, py, m.rad * 2.6, 0, Math.PI * 2);
        ctx.fill();

        // 内层实心
        ctx.beginPath();
        ctx.fillStyle = m.warm
          ? "rgba(228,250,255," + al.toFixed(3) + ")"
          : "rgba(186,228,255," + al.toFixed(3) + ")";
        ctx.arc(px, py, m.rad, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  Timer {
    interval: root.tickMs
    repeat: true
    running: root.running
    onTriggered: {
      var dt = root.tickMs / 1000;
      root.clock += dt;

      // 光环自转
      for (var i = 0; i < root.rings.length; i++) {
        root.rings[i].angle += root.rings[i].speed * dt;
      }

      // 光点上升，飘出上边界后从底部重生
      var h = root.height > 0 ? root.height : 720;
      var arr = root.motes;
      for (var j = 0; j < arr.length; j++) {
        var m = arr[j];
        m.y -= m.vy * dt;
        if (m.y < -30) root.respawnMote(m, true);
      }
      auraCanvas.requestPaint();
    }
  }

  // 淡入淡出期间也要重绘，否则 Canvas 只在 running 时刷新会顿一下
  onIntensityChanged: auraCanvas.requestPaint()
}
