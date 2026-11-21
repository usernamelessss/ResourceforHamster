// 中文 26 键竖屏左侧放大：前四列字母键从左到右递减，右侧字母键与系统键让出宽度。
local sum(arr) = std.foldl(function(acc, x) acc + x, arr, 0);
local pct(x) = { width: { percentage: x } };
// 生成 bounds 使用的分数字符串，例如 '125/160'。
local ratio(part, whole) =
  std.toString(std.floor(part * 1000 + 0.5)) + '/' + std.toString(std.floor(whole * 1000 + 0.5));

local row1Keys = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
local row2Keys = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
local row3Keys = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

{
  // 仅竖屏、非 27 键且开关开启时生效。
  enabled(context, includeSemicolon)::
    context.orientation == 'portrait'
    && !includeSemicolon
    && std.objectHas(context.Settings, 'left_enlarge_config')
    && context.Settings.left_enlarge_config.enable,

  // 覆写竖屏系统键尺寸；spaceLeftButton（逗号句号）读取的是 spaceRight键size。
  patchLayout(keyboardLayout, cfg)::
    keyboardLayout + {
      '竖屏按键尺寸'+: {
        'shift键size': pct(cfg.shift),
        'backspace键size': pct(cfg.backspace),
        '123键size': pct(cfg.bottom['123']),
        'spaceRight键size': pct(cfg.bottom.comma),
        'space键size': pct(cfg.bottom.space),
        'cn2en键size': pct(cfg.bottom.cn2en),
        'enter键size': pct(cfg.bottom.enter),
      },
    },

  // 按行重算字母键宽度；a、l 两端保留隐形触控余量。
  patchLetterSpecs(letterSpecs, cfg)::
    local margin = cfg.row2_edge_margin;
    local row1Rest = (1 - sum(cfg.row1)) / (std.length(row1Keys) - std.length(cfg.row1));
    local row2Rest = (1 - sum(cfg.row2) - 2 * margin) / (std.length(row2Keys) - std.length(cfg.row2));
    local row3Rest = (1 - cfg.shift - cfg.backspace - sum(cfg.row3)) / (std.length(row3Keys) - std.length(cfg.row3));
    assert row1Rest > 0 && row2Rest > 0 && row3Rest > 0 : 'left_enlarge_config 宽度之和超过整行';
    local sized(keys, lefts, rest) = {
      [keys[i]]: if i < std.length(lefts) then lefts[i] else rest
      for i in std.range(0, std.length(keys) - 1)
    };
    local widths =
      sized(row1Keys, cfg.row1, row1Rest) +
      sized(row2Keys, cfg.row2, row2Rest) +
      sized(row3Keys, cfg.row3, row3Rest);
    [
      local w = widths[spec.key];
      spec + (
        if spec.key == 'a' then {
          size: pct(w + margin),
          bounds: { width: ratio(w, w + margin), alignment: 'right' },
        } else if spec.key == 'l' then {
          size: pct(w + margin),
          bounds: { width: ratio(w, w + margin), alignment: 'left' },
        } else {
          size: pct(w),
          bounds: {},
        }
      )
      for spec in letterSpecs
    ],
  // 给竖屏四行按键分别加行高样式；功能行保持原样。
  patchRowHeights(layoutDef, heights)::
    assert std.length(heights) == 4 : 'row_heights 需要 4 个值';
    assert std.abs(sum(heights) - 1) < 0.002 : 'row_heights 之和应为 1';
    local styleName(i) = 'leftEnlargeRow' + (i + 1) + 'Style';
    local withStyle(row, i) = row { HStack+: { style: styleName(i) } };
    layoutDef {
      keyboardLayout: [
        if std.objectHas(item, 'HStack') && std.objectHas(item.HStack, 'style') && item.HStack.style == 'keyboardStyle' then
          item {
            HStack+: {
              subviews: [withStyle(item.HStack.subviews[i], i) for i in std.range(0, std.length(item.HStack.subviews) - 1)],
            },
          }
        else
          item
        for item in layoutDef.keyboardLayout
      ],
    } + {
      [styleName(i)]: { size: { height: { percentage: heights[i] } } }
      for i in std.range(0, 3)
    },
}