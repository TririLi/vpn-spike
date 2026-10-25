import { add } from 'libentry.so';

@Entry
@Component
struct Index {
  @State result: string = '尚未调用';

  build() {
    Column({ space: 16 }) {
      Text('Go 内核加载测试').fontSize(22).fontWeight(FontWeight.Bold)
      Text('点击调用 libgoadd.so 的 Add(1, 2)').fontSize(14).fontColor('#666666')
      Button('调用 Add(1,2)')
        .width('70%').height(48)
        .onClick(() => {
          try {
            this.result = '返回: ' + add(1, 2);
          } catch (e) {
            this.result = '异常: ' + JSON.stringify(e);
          }
        })
      Text(this.result).fontSize(18).fontColor('#00A1D6').margin({ top: 8 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }
}
