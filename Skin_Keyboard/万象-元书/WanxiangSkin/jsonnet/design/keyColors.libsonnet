// 按键单独配色：按 keyPalette 给每个字母键和部分功能键生成独立背景，并替换到对应的按键和通知上。
// 只替换普通字母键背景和功能键背景；长按气泡、划动气泡、回车的蓝色状态保持原样。
local palette = import './keyPalette.libsonnet';
local styleFactories = import './styleFactories.libsonnet';
local appearance = import './appearance.libsonnet';
local color = appearance.color;

// 配色表里的功能键名 → 键盘里对应的按键对象名
local systemTargets = {
  shift: ['shiftButton'],
  backspace: ['backspaceButton'],
  cnen: ['cn2enButton', 'en2cnButton'],
  '123': ['123Button'],
  space: ['spaceButton', 'spaceFirstButton', 'spaceSecondButton'],
  spaceRight: ['spaceLeftButton', 'spaceRightButton'],
  symbol: ['symbolButton'],
};
local replaceable = ['alphabeticBackgroundStyle', 'systemButtonBackgroundStyle'];

{
  apply(keyboard, theme, orientation, Settings)::
    if !palette.enable then keyboard
    else
      local keyColor = palette[theme].keyColor;
      local isLetter(k) = std.length(k) == 1;
      local targets =
        { [k]: [k + 'Button'] for k in std.objectFields(keyColor) if isLetter(k) } +
        { [k]: systemTargets[k] for k in std.objectFields(systemTargets) if std.objectHas(keyColor, k) };
      local styleName(k) = 'keyColor' + k + 'BackgroundStyle';
      local makeBackground(k) =
        styleFactories.makeGeometryStyle(keyColor[k], {
          insets: if orientation == 'portrait' then Settings.button_insets.portrait else Settings.button_insets.landscape,
          highlightColor: color[theme][if isLetter(k) then '字母键背景颜色-高亮' else '功能键背景颜色-高亮'],
          cornerRadius: Settings.cornerRadius,
          normalLowerEdgeColor: color[theme]['底边缘颜色-普通'],
          highlightLowerEdgeColor: color[theme]['底边缘颜色-高亮'],
        });
      // 按对象名前缀找到它属于哪个键，例如 aButton、aButtonBackslashNotification 都属于 a。
      local ownerOf(field) =
        local hits = [
          k
          for k in std.objectFields(targets)
          if std.length([p for p in targets[k] if field == p || std.startsWith(field, p)]) > 0
        ];
        if std.length(hits) > 0 then hits[0] else null;
      local canReplace(v) =
        std.type(v) == 'object' && std.objectHas(v, 'backgroundStyle')
        && std.type(v.backgroundStyle) == 'string' && std.member(replaceable, v.backgroundStyle);
      local fields = [f for f in std.objectFields(keyboard) if canReplace(keyboard[f]) && ownerOf(f) != null];
      keyboard +
      { [f]: keyboard[f] + { backgroundStyle: styleName(ownerOf(f)) } for f in fields } +
      { [styleName(k)]: makeBackground(k) for k in std.objectFields(targets) },
}