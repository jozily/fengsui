import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import Fk.Components.LunarLTK
import Fk.Pages.LunarLTK

Item {
    id: root
    // 素材文件夹路径
    property string img: "../image/Effect/bankingdoms/"

    anchors.fill: parent
    scale: 1

    // 定义当前王国（0~5有效）
    property string kingdoms
    // 动画目标帧（根据kingdoms动态计算）
    property int targetFrame: 0
    property bool initialized: false

    function initializeAnimation() {
        switch (kingdoms) {
            case "wei": targetFrame = 0; break
            case "shu": targetFrame = 1; break
            case "wu": targetFrame = 2; break
            case "qun": targetFrame = 3; break
            default: targetFrame = 4
        }
        kingdom.curr = 0
        bg.curr = 0
        bg.opacity = 0
        root.opacity = 1
        mainAnimation.restart()
    }

    Component.onCompleted: {
        initialized = true
        initializeAnimation()
    }

    // 王国图片（居中，层级在上）
    Image {
        id: kingdom
        anchors.centerIn: parent  // 水平垂直居中
        scale: 1.2                // 王国缩放（稍大以覆盖背景）
        fillMode: Image.Stretch   // 拉伸填充
        source: img + "kingdoms" + curr + ".png"
        property int curr: 0      // 当前帧索引
        opacity: 1
    }

    // 背景图片（居中，层级在下）
    Image {
        id: bg
        anchors.centerIn: kingdom     // 水平垂直居中于kingdom
        scale: 0.8                // 背景缩放（根据素材调整）
        fillMode: Image.Stretch   // 拉伸填充
        source: img + "jiasuo" + curr + ".png"
        property int curr: 0      // 当前帧索引
        opacity: 0
        z: 1
    }


    // 监听王国变化，触发动画初始化
    onKingdomsChanged: {
        if (initialized) initializeAnimation()
    }

    // 主序列动画：分两阶段执行
       SequentialAnimation {
           id:  mainAnimation
           running: false

           // 第一阶段：kingdom单独从0~4帧循环3次
           SequentialAnimation {
               PropertyAnimation {
                   target: kingdom
                   property: "curr"
                   from: 0
                   to: 5  // 固定循环0~4帧（共5帧）
                   duration: 700 // 每帧时长500ms（可根据需求调整）
                   loops: 3  // 循环3次（总播放次数：3×5=15帧）
               }
               SequentialAnimation {
                   PropertyAnimation {
                       target: kingdom
                       property: "curr"
                       from: 0
                       to: targetFrame  // 动态目标帧（0~4）
                       duration: 500
                       loops: 1  // 仅播放1次（可根据需求调整）
                   }
               }
           }

           // 第二阶段：kingdom与bg同步播放（从0到目标帧）
           ParallelAnimation {
               // kingdom同步动画（与第二阶段目标帧一致）
               // bg同步动画（与第二阶段目标帧一致）
               SequentialAnimation {
                   ScriptAction { script: bg.opacity = 1; }
                   PropertyAnimation {
                       target: bg
                       property: "curr"
                       from: 0
                       to: 60  // 动态目标帧（0~40）
                       duration: 2100  // 与kingdom动画同步
                       loops: 1  // 仅播放1次（可根据需求调整）
                   }
               }
           }
           onFinished: {
             anim2.start();
           }
       }

       //清除掉动画
       PropertyAnimation {
          id: anim2
          target: root
          property: "opacity"
          to: 0
          duration: 20
          onFinished: {
            roomScene.bigAnim.source = "";
          }
        }

    // 加载外部数据（示例）
    function loadData(data) {
        kingdoms = data.kingdoms
        initializeAnimation()
    }
}
