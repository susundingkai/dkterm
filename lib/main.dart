import 'package:dkterm/provider/connProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';
// import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/safe_area.dart';
void main() {
    runApp(
    // For widgets to be able to read providers, we need to wrap the entire
    // application in a "ProviderScope" widget.
    // This is where the state of our providers will be stored.
    const ProviderScope(
      child: TabbedViewExample(),
    ),
  );
}

class TabbedViewExample extends StatelessWidget {
  const TabbedViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: TabbedViewExamplePage());
  }
}

class TabbedViewExamplePage extends ConsumerStatefulWidget {
  const TabbedViewExamplePage({super.key});

  @override
  ConsumerState createState() => _TabbedViewExamplePageState();
}

class _TabbedViewExamplePageState extends ConsumerState<TabbedViewExamplePage> {
  late TabbedViewController _controller;

  @override
  void initState() {
    super.initState();
    List<TabData> tabs = [];
    _controller = TabbedViewController(tabs);
  }

  @override
  Widget build(BuildContext context) {
    // TabbedView tabbedView = TabbedView(controller: _controller);
        TabbedView tabbedView = TabbedView(
        controller: _controller,
        tabsAreaButtonsBuilder: (context, tabsCount) {
          List<TabButton> buttons = [];
          buttons.add(TabButton(
              icon: IconProvider.data(Icons.add),
              onPressed: () async {
                var terminal = Terminal(maxLines: 10000,);
                var terminalController = TerminalController();
                int millisecond = DateTime.now().millisecondsSinceEpoch;
                _controller.addTab(TabData(
                  text: '$millisecond',
                  content: SafeArea(child: ClipRect(child: TerminalView(
                        terminal,
                        controller: terminalController,
                        autofocus: false,
                        backgroundOpacity: 0.8,
                      ))),  
                  keepAlive: true,
                  
                ));
                _controller.selectedIndex=_controller.tabs.length-1;
                // print(DateTime.now().millisecondsSinceEpoch);
                ref.read(connServiceProvider).openTerminal(terminal,null);
              }));
          if (tabsCount > 0) {
            buttons.add(TabButton(
                icon: IconProvider.data(Icons.delete),
                onPressed: () {
                  if (_controller.selectedIndex != null) {
                    _controller.removeTab(_controller.selectedIndex!);
                  }
                }));
          }
          return buttons;
        });
    Widget w =
        TabbedViewTheme(data: TabbedViewThemeData.dark(), child: tabbedView);
    return Scaffold(body: Container(child: w));
  }
}

class _ShellCommand {
  final String command;

  final List<String> args;

  _ShellCommand(this.command, this.args);
}

_ShellCommand get _platformShell {
  if (Platform.isMacOS) {
    final user = Platform.environment['USER'];
    return _ShellCommand('login', ['-fp', user!]);
    
  }

  if (Platform.isWindows) {
    return _ShellCommand('powershell.exe', []);
  }

  final shell = Platform.environment['SHELL'] ?? 'sh';
  return _ShellCommand(shell, []);
}