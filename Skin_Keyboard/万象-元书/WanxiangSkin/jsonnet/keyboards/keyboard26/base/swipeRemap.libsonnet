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

// 给某个字母键加「输入中」通知：有预编辑时上划换成 swipeUpAction，上划角标换成 icon。
// 点按、下划保持不变；预编辑清空后按键恢复原样。
local preeditKey(keyboard, key, swipeUpAction, icon) =
  local name = key + 'Button';
  if !std.objectHas(keyboard, name) then {}
  else
    local btn = keyboard[name];
    local upStyle = name + 'UpForegroundStyle';
    local preeditUpStyle = name + 'PreeditUpForegroundStyle';
    local notificationName = name + 'PreeditNotification';
    local hasUpStyle = std.objectHas(keyboard, upStyle);
    local swapUp(names) =
      if std.type(names) == 'array' then
        [if n == upStyle then preeditUpStyle else n for n in names]
      else if names == upStyle then preeditUpStyle
      else names;
    {
      [name]: btn + {
        notification: [notificationName] + (if std.objectHas(btn, 'notification') then btn.notification else []),
      },
      [notificationName]: {
        notificationType: 'preeditChanged',
        [if std.objectHas(btn, 'backgroundStyle') then 'backgroundStyle']: btn.backgroundStyle,
        [if std.objectHas(btn, 'foregroundStyle') then 'foregroundStyle']:
          if hasUpStyle then swapUp(btn.foregroundStyle) else btn.foregroundStyle,
        [if std.objectHas(btn, 'action') then 'action']: btn.action,
        swipeUpAction: swipeUpAction,
        [if std.objectHas(btn, 'swipeDownAction') then 'swipeDownAction']: btn.swipeDownAction,
      },
    } + (
      if hasUpStyle then {
        [preeditUpStyle]: keyboard[upStyle] + {
          buttonStyleType: 'systemImage',
          systemImageName: icon,
          text:: null,
        },
      } else {}
    );

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
      // 输入状态下的 h、z 上划由 preeditPatch 处理。
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

  // 中文 26 键输入状态（有预编辑）时的上划：
  //   h：功能行第 7 个按钮（tail）在输入中的功能，向方案发送 backslash。
  //   z：简繁切换，发送万象 key_binder 里绑定 s2t 的 Control+Shift+4，当前候选立即刷新。
  preeditPatch(context, keyboard)::
    if !self.enabled(context) then {}
    else
      local settings = context.Settings;
      local dark = context.theme == 'dark';
      preeditKey(
        keyboard,
        'h',
        { sendKeys: 'backslash' },
        if settings.fix_sf_symbol then 'ellipsis.curlybraces' else 'ellipsis.viewfinder'
      ) +
      preeditKey(
        keyboard,
        'z',
        { sendKeys: 'Control+Shift+4' },
        if dark then 'arrow.trianglehead.2.clockwise.rotate.90.circle.fill' else 'arrow.trianglehead.2.clockwise.rotate.90.circle'
      ),
}