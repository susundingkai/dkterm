import 'dart:convert';
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
  runApp(TabbedViewExample());
}

class TabbedViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false, home: TabbedViewExamplePage());
  }
}

class TabbedViewExamplePage extends StatefulWidget {
  @override
  _TabbedViewExamplePageState createState() => _TabbedViewExamplePageState();
}

class _TabbedViewExamplePageState extends State<TabbedViewExamplePage> {
  late TabbedViewController _controller;

  @override
  void initState() {
    super.initState();
    List<TabData> tabs = [];
    _controller = TabbedViewController(tabs);
  }
  @riverpod
  Future<Pty> attach({
    Terminal? terminal,
    Map<String, String>? environment,
  }) async {
    final shell = _platformShell;
    final pty = Pty.start(
      shell.command,
      arguments: shell.args,
      environment: {...Platform.environment, ...environment ?? {}},
      rows: terminal?.viewHeight ?? 60,
      columns: terminal?.viewWidth ?? 80,
    );
    print("end");
    print(DateTime.now().millisecondsSinceEpoch);
    return pty;
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
                print(DateTime.now().millisecondsSinceEpoch);
                
                attach(terminal: terminal).then((pty) => { ////////////////////////////////////////////////
                  pty.output
                    .cast<List<int>>()
                    .transform(const Utf8Decoder())
                    .listen(terminal.write),
                  
                  pty.exitCode.then((code) {
                    terminal.write('the process exited with exit code $code');
                    }),
                  terminal.onOutput = (data) {
                      dynamic conv= const Utf8Encoder().convert(data);
                      pty.write(conv);
                    },
                  terminal.onResize = (w, h, pw, ph) {
                      pty.resize(h, w);
                    }
                  });
                print(DateTime.now().millisecondsSinceEpoch);
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