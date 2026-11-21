// 中文 26 键竖屏左侧放大：前四列字母键从左到右递减，右侧字母键与系统键让出宽度。
// 可选 move_ep_to_bottom：把 e、p 按键原样移到底行，只改位置不改功能。
// 开启后底行顺序：123 ，。 中英 空格 p e 换行
local sum(arr) = std.foldl(function(acc, x) acc + x, arr, 0);
local pct(x) = { width: { percentage: x } };
local ratio(part, whole) =
  std.toString(std.floor(part * 1000 + 0.5)) + '/' + std.toString(std.floor(whole * 1000 + 0.5));
local allRow1Keys = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
local row2Keys = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
local row3Keys = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];
// 移到空格右侧的字母键，按显示顺序排列
local movedKeys = ['p', 'e'];

local moveEp(cfg) = std.objectHas(cfg, 'move_ep_to_bottom') && cfg.move_ep_to_bottom;
local row1KeysOf(cfg) =
  if moveEp(cfg) then std.filter(function(k) !std.member(movedKeys, k), allRow1Keys) else allRow1Keys;
local bottomKeysOf(cfg) =
  ['123', 'comma', 'space', 'cn2en', 'enter'] + (if moveEp(cfg) then movedKeys else []);
local cellName(v) = if std.objectHas(v, 'Cell') then v.Cell else null;
local isMovedCell(v) = std.member([k + 'Button' for k in movedKeys], cellName(v));
local isCn2enCell(v) = cellName(v) == 'cn2enButton';

// 底行重排：中英键移到空格左侧，e/p 插在空格右侧。
local reorderBottom(subs) =
  local cn2enCells = std.filter(isCn2enCell, subs);
  std.flattenArrays([
    if isCn2enCell(v) then []
    else if cellName(v) == 'spaceButton' then cn2enCells + [v] + [{ Cell: k + 'Button' } for k in movedKeys]
    else [v]
    for v in subs
  ]);

{
  enabled(context, includeSemicolon)::
    context.orientation == 'portrait' && !includeSemicolon
    && std.objectHas(context.Settings, 'left_enlarge_config')
    && context.Settings.left_enlarge_config.enable,

  patchLayout(keyboardLayout, cfg)::
    local bottomSum = sum([cfg.bottom[k] for k in bottomKeysOf(cfg)]);
    assert std.abs(bottomSum - 1) < 0.002 : 'left_enlarge_config.bottom 之和应为 1，当前为 ' + bottomSum;
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

  patchLetterSpecs(letterSpecs, cfg)::
    local row1Keys = row1KeysOf(cfg);
    local margin = cfg.row2_edge_margin;
    local row1Rest = (1 - sum(cfg.row1)) / (std.length(row1Keys) - std.length(cfg.row1));
    local row2Rest = (1 - sum(cfg.row2) - 2 * margin) / (std.length(row2Keys) - std.length(cfg.row2));
    local row3Rest = (1 - cfg.shift - cfg.backspace - sum(cfg.row3)) / (std.length(row3Keys) - std.length(cfg.row3));
    assert row1Rest > 0 && row2Rest > 0 && row3Rest > 0 : 'left_enlarge_config 宽度之和超过整行';
    local sized(keys, lefts, rest) = {
      [keys[i]]: if i < std.length(lefts) then lefts[i] else rest
      for i in std.range(0, std.length(keys) - 1)
    };
    local movedWidths = if moveEp(cfg) then { [k]: cfg.bottom[k] for k in movedKeys } else {};
    local widths = sized(row1Keys, cfg.row1, row1Rest) + sized(row2Keys, cfg.row2, row2Rest)
                   + sized(row3Keys, cfg.row3, row3Rest) + movedWidths;
    [
      local w = widths[spec.key];
      spec + (
        if spec.key == 'a' then { size: pct(w + margin), bounds: { width: ratio(w, w + margin), alignment: 'right' } }
        else if spec.key == 'l' then { size: pct(w + margin), bounds: { width: ratio(w, w + margin), alignment: 'left' } }
        else { size: pct(w), bounds: {} }
      )
      for spec in letterSpecs
    ],

  // 处理竖屏中文 26 键的行结构：按需移动 e/p 和中英键，按需设置行高。
  patchPortraitLayout(layoutDef, cfg)::
    local heights = if std.objectHas(cfg, 'row_heights') then cfg.row_heights else null;
    assert heights == null || std.length(heights) == 4 : 'row_heights 需要 4 个值';
    assert heights == null || std.abs(sum(heights) - 1) < 0.002 : 'row_heights 之和应为 1';
    local styleName(i) = 'leftEnlargeRow' + (i + 1) + 'Style';
    local moveSubviews(subs, i) =
      if !moveEp(cfg) then subs
      else if i == 0 then std.filter(function(v) !isMovedCell(v), subs)
      else if i == 3 then reorderBottom(subs)
      else subs;
    local patchRow(row, i) =
      row {
        HStack+: { subviews: moveSubviews(row.HStack.subviews, i) }
                 + (if heights != null then { style: styleName(i) } else {}),
      };
    layoutDef {
      keyboardLayout: [
        if std.objectHas(item, 'HStack') && std.objectHas(item.HStack, 'style') && item.HStack.style == 'keyboardStyle' then
          item { HStack+: { subviews: [patchRow(item.HStack.subviews[i], i) for i in std.range(0, std.length(item.HStack.subviews) - 1)] } }
        else item
        for item in layoutDef.keyboardLayout
      ],
    } + (if heights != null then { [styleName(i)]: { size: { height: { percentage: heights[i] } } } for i in std.range(0, 3) } else {}),
}