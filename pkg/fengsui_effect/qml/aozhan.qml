import QtQuick

Item {
  id: root
  // 鏖战.BB
  //property int sceneHeight: 720
  //property int sceneWidth: 1280
  property string img: "../image/aozhan/"
  //素材文件夹

  anchors.fill: parent
  scale: 0.75
  Rectangle {
    id: mask
    scale: 1 / 0.75
    color: "black"
    anchors.fill: parent
    opacity: 0.7
  }

  Image {
    id: bg
    anchors.centerIn: parent
    scale: 1
    source: img + "aozhan" + curr + ".png"
    property int curr: 0
    opacity: 1
  }

  //静态
  ParallelAnimation {
    id: step1
    running: true
    // bg
    PropertyAnimation {
      target: bg
      property: "scale"
      to: 1.5
      duration: 2200
      easing.type: Easing.InQuad
    }
    //动画
    SequentialAnimation {
          PauseAnimation { duration: 50 }
          ScriptAction { script: bg.opacity = 1; }
          PropertyAnimation {
            target: bg
            property: "curr"
            to: 28
            duration: 3000
          }
        }
    onFinished: {
      anim2.start();
    }
  }

  PropertyAnimation {
     id: anim2
     target: root
     property: "opacity"
     to: 0
     duration: 560
     onFinished: {
       roomScene.bigAnim.source = "";
     }
   }
}
