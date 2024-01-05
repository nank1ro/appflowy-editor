import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Show the greater menu
///
/// - support
///   - desktop
///   - web
///
final CharacterShortcutEvent greaterCommand = CharacterShortcutEvent(
  key: 'show the greater menu',
  character: '>',
  handler: (editorState) async {
    final context = editorState.getNodeAtPath([0])!.context!;
    return await _showGreaterMenu(
      editorState,
      standardSelectionMenuItems,
      style: Theme.of(context).brightness == Brightness.dark
          ? SelectionMenuStyle.dark
          : SelectionMenuStyle.light,
    );
  },
);

CharacterShortcutEvent customGreaterCommand(
  List<SelectionMenuItem> items, {
  bool shouldInsertGreater = true,
  SelectionMenuStyle style = SelectionMenuStyle.light,
}) {
  return CharacterShortcutEvent(
    key: 'show the greater menu',
    character: '>',
    handler: (editorState) => _showGreaterMenu(
      editorState,
      items,
      shouldInsertGreater: shouldInsertGreater,
      style: style,
    ),
  );
}

final Set<String> supportSlashMenuNodeWhiteList = {
  ParagraphBlockKeys.type,
  HeadingBlockKeys.type,
  TodoListBlockKeys.type,
  BulletedListBlockKeys.type,
  NumberedListBlockKeys.type,
  QuoteBlockKeys.type,
};

SelectionMenuService? _selectionMenuService;
Future<bool> _showGreaterMenu(
  EditorState editorState,
  List<SelectionMenuItem> items, {
  bool shouldInsertGreater = true,
  SelectionMenuStyle style = SelectionMenuStyle.light,
}) async {
  if (PlatformExtension.isMobile) {
    return false;
  }

  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }

  // delete the selection
  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  final afterSelection = editorState.selection;
  if (afterSelection == null || !afterSelection.isCollapsed) {
    assert(false, 'the selection should be collapsed');
    return true;
  }

  final node = editorState.getNodeAtPath(selection.start.path);

  // only enable in white-list nodes
  if (node == null || !_isSupportGreaterMenuNode(node)) {
    return false;
  }

  // insert the greater character
  if (shouldInsertGreater) {
    if (kIsWeb) {
      // Have no idea why the focus will lose after inserting on web.
      keepEditorFocusNotifier.increase();
      await editorState.insertTextAtPosition('>', position: selection.start);
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => keepEditorFocusNotifier.decrease(),
      );
    } else {
      await editorState.insertTextAtPosition('>', position: selection.start);
    }
  }

  // show the greater menu
  () {
    // this code is copied from the the old editor.
    // TODO: refactor this code
    final context = editorState.getNodeAtPath(selection.start.path)?.context;
    if (context != null) {
      _selectionMenuService = SelectionMenu(
        context: context,
        editorState: editorState,
        selectionMenuItems: items,
        deleteSlashByDefault: shouldInsertGreater,
        style: style,
      );
      _selectionMenuService?.show();
    }
  }();

  return true;
}

bool _isSupportGreaterMenuNode(Node node) {
  var result = supportSlashMenuNodeWhiteList.contains(node.type);
  if (node.level > 1 && node.parent != null) {
    return result && _isSupportGreaterMenuNode(node.parent!);
  }
  return result;
}
