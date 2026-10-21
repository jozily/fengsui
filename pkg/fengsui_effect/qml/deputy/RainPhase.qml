// 烽燧燎原 · 悼离额外出牌阶段 · 骤雨氛围
// 由 skills/fengsui_effect_daoli_rain.lua 通过 doSuperLightBox 调用：
//   loadData({ running = true })             开始下雨（雨声循环播放）
//   loadData({ running = false })            停雨（淡出后 finish）
//   loadData({ running = true, storm = true}) 雷暴档（雨量翻倍 + 偶发闪电）
//
// 两条设计约束，改动前请先读：
//   1. 雨丝全部由 Canvas 程序化绘制，不依赖任何图片素材。
//   2. 雨声用 MediaPlayer + loops: Infinite 自行循环，绕开 Backend.playSound
//      只能播一次性文件的限制；音量跟随 Cpp.volume()（玩家设置里的效果音量），
//      玩家把效果音调成 0 时这里也应当静音。
//   3. quiet_rain.mp3 是已处理过的无缝循环版，且**电平已归一化**：
//      原始素材录音极轻（mean -49.4 dB / peak -20.2 dB），比游戏 BGM（mean -17.5 dB）
//      低 32 dB，乘上音量系数后约 -62 dB，实测完全听不见。
//      现已 +27.7 dB 并加限幅（输出 mean -22.1 dB / peak -2.9 dB，循环接缝 -21.6→-21.9 dB）。
//      换素材时必须同时重做「首尾交叉淡化」和「电平归一化」两步，否则不是静音就是爆音。
//
// 收尾统一走 finish()，并校验 item === root，防止覆盖后到的新特效。

import QtQuick
import QtMultimedia

// 必须 import Fk：Cpp 单例（Cpp.path / Cpp.volume）由 Fk 模块提供，
// 缺了这行 Cpp 就是 undefined，audioPath 会整个变成 undefined → 有雨幕但完全没有声音。
// 同目录其它特效（GzygSoulBox.qml 等）也都依赖 Fk 才能用 Cpp。
import Fk

Item {
  id: root
  anchors.fill: parent
  enabled: false // 纯氛围层，不拦截任何鼠标事件，出牌操作照常穿透

  property bool running: false
  property bool everStarted: false
  property bool storm: false
  property real intensity: 0
  property var drops: []

  // 素材已归一化到 mean ≈ -22 dB，所以这里只需做「床」的衰减，不再承担补增益。
  // 默认效果音量 50 → 0.5 × 0.75 = 0.375（-8.5 dB），落在 BGM 之下约 11 dB。
  readonly property real baseVolume: 0.75
  readonly property int lightDrops: 130
  readonly property int stormDrops: 260
  readonly property int tickMs: 40
  // 音源随特效包一起存放，删掉 pkg/fengsui_effect 即可整体还原。
  // 用「相对本文件的 URL」解析，而不是 Cpp.path 拼绝对路径：
  //   ① 不依赖场景里有没有 Cpp（这行曾因缺 import Fk 抛 ReferenceError，导致彻底没声音）；
  //   ② 包放在应用目录或用户目录都能正确定位。
  readonly property url audioPath:
    Qt.resolvedUrl("../../audio/ambience/quiet_rain.mp3")

  function finish() {
    if (roomScene && roomScene.bigAnim && roomScene.bigAnim.item === root) {
      roomScene.bigAnim.source = "";
    }
  }

  // 雨声音量 = 玩家效果音量 × 本层基准音量；读不到就当满音量。
  // 雷暴档只把雨声抬一点，不换音源——素材本身是均匀的雨，换曲反而破坏连续感。
  function sfxGain() {
    var v = 100;
    try { v = Cpp.volume(); } catch (e) { v = 100; }
    if (typeof v !== "number" || isNaN(v)) v = 100;
    var base = root.baseVolume * (root.storm ? 1.18 : 1.0);
    return Math.max(0, Math.min(1, v / 100)) * base;
  }

  function freshAlpha() {
    return 0.14 + Math.random() * 0.34;
  }

  function cssFor(a) {
    return "rgba(200,220,245," + a.toFixed(3) + ")";
  }

  function makeDrops() {
    var arr = [];
    for (var i = 0; i < root.stormDrops; i++) {
      var a = root.freshAlpha();
      arr.push({
        x: Math.random() * ((root.width > 0 ? root.width : 1280) + 160) - 80,
        y: Math.random() * (root.height > 0 ? root.height : 720),
        len: 18 + Math.random() * 30,
        drift: 4 + Math.random() * 6,
        w: 0.8 + Math.random() * 1.0,
        speed: 520 + Math.random() * 360,
        css: root.cssFor(a)
      });
    }
    return arr;
  }

  function start() {
    if (root.running) return;
    root.running = true;
    root.everStarted = true;
    stopSeq.stop();
    fadeIn.to = 1;
    fadeVol.to = root.sfxGain();
    startSeq.restart();
  }

  function loadData(d) {
    d = d || {};
    if (d.storm === true) root.storm = true;
    if (d.running === false) {
      // 从没真正播过（例如刚被别的特效抢占、整个 item 是新造的）就直接收尾，
      // 不要为了 0.01 的透明度再跑一遍淡出，否则会闪一下雨。
      if (!root.everStarted || root.intensity < 0.02) {
        rainSfx.stop();
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
    root.drops = root.makeDrops();
    root.start();
  }

  Component.onDestruction: {
    rainSfx.stop(); // 被别的特效顶掉时 item 会被销毁，确保声音不残留
  }

  // ── 雨声：循环播放，音量淡入淡出 ─────────────────────────────
  MediaPlayer {
    id: rainSfx
    source: root.audioPath
    loops: MediaPlayer.Infinite
    audioOutput: AudioOutput {
      id: rainOut
      volume: 0
    }
    onPlaybackStateChanged: {
      // loops: Infinite 正常情况下不会走到 Stopped；这里只防多轨设备切换之类的意外中断
      if (root.running && playbackState === MediaPlayer.StoppedState) {
        play();
      }
    }
    // 解码/路径出错时留一行日志，方便在客户端日志里定位「为什么没声音」
    onErrorOccurred: function (error, errorString) {
      console.warn("[fengsui_effect] rain sfx failed:", error, errorString, root.audioPath);
    }
  }

  ParallelAnimation {
    id: startSeq
    NumberAnimation {
      id: fadeIn
      target: root
      property: "intensity"
      to: 1
      duration: 900
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      id: fadeVol
      target: rainOut
      property: "volume"
      to: 0
      duration: 1500
      easing.type: Easing.OutCubic
    }
    ScriptAction {
      script: {
        if (rainSfx.playbackState !== MediaPlayer.PlayingState) rainSfx.play();
      }
    }
  }

  SequentialAnimation {
    id: stopSeq
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "intensity"
        to: 0
        duration: 650
        easing.type: Easing.InCubic
      }
      NumberAnimation {
        target: rainOut
        property: "volume"
        to: 0
        duration: 950
        easing.type: Easing.InCubic
      }
    }
    ScriptAction {
      script: {
        rainSfx.stop();
        root.finish();
      }
    }
  }

  // ── 雨天压暗：很轻，只做氛围，不压住牌面 ─────────────────────
  Rectangle {
    anchors.fill: parent
    color: "#0A1420"
    opacity: root.intensity * (root.storm ? 0.16 : 0.10)
  }

  // ── 雨丝 ─────────────────────────────────────────────────
  Canvas {
    id: rainCanvas
    anchors.fill: parent
    opacity: root.intensity

    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      ctx.lineCap = "round";
      var count = Math.min(root.storm ? root.stormDrops : root.lightDrops, root.drops.length);
      var arr = root.drops;
      for (var i = 0; i < count; i++) {
        var d = arr[i];
        ctx.strokeStyle = d.css;
        ctx.lineWidth = d.w;
        ctx.beginPath();
        ctx.moveTo(d.x, d.y);
        ctx.lineTo(d.x - d.drift, d.y - d.len);
        ctx.stroke();
      }
    }
  }

  Timer {
    interval: root.tickMs
    repeat: true
    running: root.running
    onTriggered: {
      var dt = root.tickMs / 1000;
      var w = root.width;
      var h = root.height;
      var arr = root.drops;
      for (var i = 0; i < arr.length; i++) {
        var d = arr[i];
        d.y += d.speed * dt;
        d.x += d.speed * dt * 0.13;
        if (d.y > h + d.len + 10 || d.x > w + 100) {
          var a = root.freshAlpha();
          d.x = Math.random() * (w + 160) - 80;
          d.y = -Math.random() * 260 - 20;
          d.len = 18 + Math.random() * 30;
          d.drift = 4 + Math.random() * 6;
          d.w = 0.8 + Math.random() * 1.0;
          d.speed = 520 + Math.random() * 360;
          d.css = root.cssFor(a);
        }
      }
      rainCanvas.requestPaint();
    }
  }

  // ── 雷暴档专属：偶发闪电（小雨档永不触发）─────────────────────
  Rectangle {
    id: flash
    anchors.fill: parent
    color: "#E8F2FF"
    opacity: 0
  }

  Timer {
    interval: 5000
    repeat: true
    running: root.running && root.storm
    onTriggered: {
      boltAnim.restart();
      interval = 3600 + Math.random() * 4200;
    }
  }

  SequentialAnimation {
    id: boltAnim
    NumberAnimation { target: flash; property: "opacity"; to: 0.11; duration: 55 }
    NumberAnimation { target: flash; property: "opacity"; to: 0.02; duration: 85 }
    NumberAnimation { target: flash; property: "opacity"; to: 0.09; duration: 45 }
    NumberAnimation { target: flash; property: "opacity"; to: 0.0; duration: 240 }
  }
}
