// 中文 26 键竖屏：左侧前四列字母键放大，从左往右递减；右侧字母键和 Shift / 删除键让出宽度。
// 只改竖屏中文 26 键字母区的宽度。底行、按键功能、横屏、英文键盘、27 键都不受影响。
local config = {
  enable: true,
  row1: [0.115, 0.110, 0.105, 0.102],  // q w e r
  row2: [0.125, 0.118, 0.112, 0.108],  // a s d f
  row2_edge_margin: 0,                 // a 左侧、l 右侧留白；0 = 铺满（原版 0.05）
  row3: [0.120, 0.113, 0.107, 0.103],  // z x c v
  shift: 0.125,                        // 原版 0.15
  backspace: 0.13,                     // 原版 0.15
};

local sum(arr) = std.foldl(function(acc, x) acc + x, arr, 0);
local pct(x) = { width: { percentage: x } };
local ratio(part, whole) =
  std.toString(std.floor(part * 1000 + 0.5)) + '/' + std.toString(std.floor(whole * 1000 + 0.5));
local row1Keys = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
local row2Keys = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
local row3Keys = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

{
  // Custom.libsonnet 里如果写了 left_enlarge_config，会覆盖上面的默认值；没写就用默认值。
  resolveConfig(settings)::
    config + (if std.objectHas(settings, 'left_enlarge_config') then settings.left_enlarge_config else {}),

  enabled(context, includeSemicolon, cfg)::
    context.orientation == 'portrait' && !includeSemicolon && cfg.enable,

  patchLayout(keyboardLayout, cfg)::
    keyboardLayout + {
      '竖屏按键尺寸'+: {
        'shift键size': pct(cfg.shift),
        'backspace键size': pct(cfg.backspace),
      },
    },

  patchLetterSpecs(letterSpecs, cfg)::
    local margin = cfg.row2_edge_margin;
    local row1Rest = (1 - sum(cfg.row1)) / (std.length(row1Keys) - std.length(cfg.row1));
    local row2Rest = (1 - sum(cfg.row2) - 2 * margin) / (std.length(row2Keys) - std.length(cfg.row2));
    local row3Rest = (1 - cfg.shift - cfg.backspace - sum(cfg.row3)) / (std.length(row3Keys) - std.length(cfg.row3));
    assert row1Rest > 0 && row2Rest > 0 && row3Rest > 0 : 'leftEnlarge 宽度之和超过整行';
    local sized(keys, lefts, rest) = {
      [keys[i]]: if i < std.length(lefts) then lefts[i] else rest
      for i in std.range(0, std.length(keys) - 1)
    };
    local widths = sized(row1Keys, cfg.row1, row1Rest) + sized(row2Keys, cfg.row2, row2Rest) + sized(row3Keys, cfg.row3, row3Rest);
    // 有留白时 a / l 的触控区包含留白，可见按键靠内侧；margin 为 0 时按普通键处理。
    local edgeKey(w, alignment) =
      if margin > 0 then { size: pct(w + margin), bounds: { width: ratio(w, w + margin), alignment: alignment } }
      else { size: pct(w), bounds: {} };
    [
      local w = widths[spec.key];
      spec + (
        if spec.key == 'a' then edgeKey(w, 'right')
        else if spec.key == 'l' then edgeKey(w, 'left')
        else { size: pct(w), bounds: {} }
      )
      for spec in letterSpecs
    ],
}