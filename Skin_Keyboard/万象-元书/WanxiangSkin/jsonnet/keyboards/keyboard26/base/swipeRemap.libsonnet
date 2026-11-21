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
      // 关闭功能行后 data 里 b、m 会切到另一套动作，这里固定成现在使用的那套，保持不变。
      local yuan = {
        action: { sendKeys: 'R' },
        label: { systemImageName: if settings.fix_sf_symbol then 'dollarsign.square.fill' else 'chineseyuanrenminbisign.square.fill' },
      };
      // 中文 h 上划（非输入状态）：直接上屏「/」，不经过方案（万象里单独的 / 会进入符号模式）。
      // 输入状态下的 h 上划由 preeditPatch 处理。
      local keepUp =
        if kind == 'pinyin' then {
          h: { action: { symbol: '/' }, label: { text: '/' } },
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

  // 中文 26 键输入状态（有预编辑）时，h 上划改为功能行第 7 个按钮（tail）在输入中的功能：
  // 向方案发送 backslash，上划角标换成同一个图标。点按、下划保持不变。
  preeditPatch(context, keyboard)::
    if !self.enabled(context) || !std.objectHas(keyboard, 'hButton') then {}
    else
      local settings = context.Settings;
      local btn = keyboard.hButton;
      local hasUpStyle = std.objectHas(keyboard, 'hButtonUpForegroundStyle');
      local icon = if settings.fix_sf_symbol then 'ellipsis.curlybraces' else 'ellipsis.viewfinder';
      local swapUp(names) =
        if std.type(names) == 'array' then
          [if n == 'hButtonUpForegroundStyle' then 'hButtonPreeditUpForegroundStyle' else n for n in names]
        else names;
      {
        hButton: btn + {
          notification: ['hButtonPreeditNotification'] + (if std.objectHas(btn, 'notification') then btn.notification else []),
        },
        hButtonPreeditNotification: {
          notificationType: 'preeditChanged',
          backgroundStyle: btn.backgroundStyle,
          foregroundStyle: if hasUpStyle then swapUp(btn.foregroundStyle) else btn.foregroundStyle,
          action: btn.action,
          swipeUpAction: { sendKeys: 'backslash' },
          [if std.objectHas(btn, 'swipeDownAction') then 'swipeDownAction']: btn.swipeDownAction,
        },
      } + (
        if hasUpStyle then {
          hButtonPreeditUpForegroundStyle: keyboard.hButtonUpForegroundStyle + {
            buttonStyleType: 'systemImage',
            systemImageName: icon,
            text:: null,
          },
        } else {}
      ),
}