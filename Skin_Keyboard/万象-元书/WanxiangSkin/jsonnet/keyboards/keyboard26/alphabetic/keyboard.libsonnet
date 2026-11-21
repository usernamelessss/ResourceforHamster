// 暴露英文 26 键入口，衔接共享上下文与构建模块。
local Settings = import '../../../Custom.libsonnet';
local buildContext = import '../../../build/context.libsonnet';
local keyboard26AlphabeticBuilder = import './builder.libsonnet';
local swipeData = import './data.libsonnet';
local swipeRemap = import '../base/swipeRemap.libsonnet';

local defaultContext = buildContext.new(Settings, 'light', 'portrait', 'iPhone');
local defaultSwipeDataRoot = swipeData.genSwipeenData(defaultContext.deviceType);
local defaultDataSwipeUp = if std.objectHas(defaultSwipeDataRoot, 'swipe_up') then defaultSwipeDataRoot.swipe_up else {};
local defaultDataSwipeDown = if std.objectHas(defaultSwipeDataRoot, 'swipe_down') then defaultSwipeDataRoot.swipe_down else {};
// 与 builder 使用同一套上下划重排，避免其他键盘复用 createButton 时出现旧的滑动功能。
local defaultRemapped = swipeRemap.apply(defaultContext, 'alphabetic', defaultDataSwipeUp, defaultDataSwipeDown);

local build(theme, orientation, keyboardLayout=null) =
  local context = buildContext.new(Settings, theme, orientation, 'iPhone');
  local resolvedKeyboardLayout = if keyboardLayout == null then buildContext.getKeyboardLayout(context) else keyboardLayout;
  keyboard26AlphabeticBuilder.build(context, resolvedKeyboardLayout);

{
  createButton: keyboard26AlphabeticBuilder.createButtonFactory(
    defaultContext,
    defaultRemapped.up,
    defaultRemapped.down
  ),
  keyboard(theme, orientation, keyboardLayout):
    build(theme, orientation, keyboardLayout),
  new(theme, orientation):
    build(theme, orientation),
}