import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:xterm/xterm.dart';
part 'connProvider.g.dart';
@riverpod
class ConnService extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // 4. return a value (or do nothing if the return type is void)
  }

  Future<void> openTerminal(Terminal? terminal,Map<String, String>? environment,TabbedViewController _controller) async {
        // 5. read the repository using ref
    // 6. set the loading state
    state = const AsyncValue.loading();
    // 7. sign in and update the state (data or error)
    int millisecond = DateTime.now().millisecondsSinceEpoch;
          var terminalController = TerminalController();

    _controller.addTab(TabData(
      text: '$millisecond',
      content: SafeArea(child: ClipRect(child: TerminalView(
            terminal!,
            controller: terminalController,
            autofocus: false,
            backgroundOpacity: 0.8,
          ))),  
      keepAlive: true,
    ));
    // compute((message) => attach, {terminal,null});
      final shell = _platformShell;
      final pty = Pty.start(
        shell.command,
        arguments: shell.args,
        rows: 60,
        columns: 80,
      );
    // await Isolate.spawn(attach,{terminal,null}, [receivePort.sendPort, "My Custom Message"]);
      pty.output
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal?.write);
      
      pty.exitCode.then((code) {
        terminal?.write('the process exited with exit code $code');
        });

      terminal?.onOutput = (data) {
          dynamic conv= const Utf8Encoder().convert(data);
          pty.write(conv);
        };
      terminal?.onResize = (w, h, pw, ph) {
          pty.resize(h, w);
        };
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

// final connServiceProvider = Provider(
//   name: 'tabsServiceProvider',
//   (ref) => ConnService(ref),
// );
