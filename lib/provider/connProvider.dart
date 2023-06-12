import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

class ConnService {
  final Ref ref;

  ConnService(this.ref);

  void openTerminal(Terminal? terminal,Map<String, String>? environment) {
    final shell = _platformShell;
    final pty = Pty.start(
      shell.command,
      arguments: shell.args,
      environment: {...Platform.environment, ...environment ?? {}},
      rows: terminal?.viewHeight ?? 60,
      columns: terminal?.viewWidth ?? 80,
    );
    pty.output
      .cast<List<int>>()
      .transform(const Utf8Decoder())
      .listen(terminal!.write);
    
    pty.exitCode.then((code) {
      terminal.write('the process exited with exit code $code');
      });

    terminal.onOutput = (data) {
        dynamic conv= const Utf8Encoder().convert(data);
        pty.write(conv);
      };
    terminal.onResize = (w, h, pw, ph) {
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

final connServiceProvider = Provider(
  name: 'tabsServiceProvider',
  (ref) => ConnService(ref),
);
