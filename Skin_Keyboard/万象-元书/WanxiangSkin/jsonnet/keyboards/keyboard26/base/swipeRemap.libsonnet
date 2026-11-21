// 去掉功能行后，把功能行里的编辑功能挪到字母键的上下划上。中文 26 键和英文 26 键共用这一份。
// 只在 iPhone 且关闭功能行时生效；iPad、或者重新打开功能行时，全部保持原样。
local edit = {
  head: { action: { shortcut: '#行首' }, label: { systemImageName: 'arrow.left.to.line' } },
  tail: { action: { shortcut: '#行尾' }, label: { systemImageName: 'arrow.right.to.line' } },
  select: { action: { shortcut: '#selectText' }, label: { systemImageName: 'selection.pin.in.out' } },
  cut: { action: { shortcut: '#cut' }, label: { systemImageName: 'scissors' } },
  copy: { action: { shortcut: '#copy' }, label: { systemImageName: 'arrow.up.doc.on.clipboard' } },
  paste: { action: { shortcut: '#paste' }, label: { systemImageName: 'doc.on.clipboard.fill' } },
};

{
  enabled(context):: context.deviceType == 'iPhone' && !context.withFunctionsRow,

  // kind: 'pinyin' 或 'alphabetic'。a、n 的对调和转移使用各自键盘原来的动作，中文仍走方案、英文仍直接上屏。
  apply(context, kind, swipeUp, swipeDown)::
    if !self.enabled(context) then { up: swipeUp, down: swipeDown }
    else
      local settings = context.Settings;
      // 关闭功能行后 data 里 b、m、h 会切到另一套动作，这里固定成现在使用的那套，保持不变。
      local yuan = {
        action: { sendKeys: 'R' },
        label: { systemImageName: if settings.fix_sf_symbol then 'dollarsign.square.fill' else 'chineseyuanrenminbisign.square.fill' },
      };
      local keepUp =
        if kind == 'pinyin' then {
          h: {
            action: if settings.function_button_config.enable_notification then { symbol: '\\' } else { character: '\\' },
            label: { text: '\\' },
          },
        } else {};
      local keepDown =
        { b: yuan } +
        (if kind == 'pinyin' then { m: { action: { character: '`' }, label: { systemImageName: 'rectangle.3.group.fill' } } } else {});
      {
        up: swipeUp + keepUp + {
          x: edit.tail,
          c: edit.cut,
          a: swipeUp.n,  // a、n 上划对调
          n: swipeUp.a,
        },
        down: swipeDown + keepDown + {
          x: edit.head,
          c: edit.copy,
          v: edit.paste,
          a: edit.select,
          n: swipeDown.a,  // a 原来的下划挪到 n，覆盖 n 原来的下划
        },
      },
}