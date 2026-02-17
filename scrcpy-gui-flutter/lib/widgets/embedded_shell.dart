import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_pty/flutter_pty.dart';
import '../providers/app_state.dart';

class EmbeddedShell extends StatefulWidget {
  final String deviceId;
  const EmbeddedShell({super.key, required this.deviceId});

  @override
  State<EmbeddedShell> createState() => _EmbeddedShellState();
}

class _EmbeddedShellState extends State<EmbeddedShell> {
  late final Terminal _terminal;
  final TerminalController _controller = TerminalController();
  Pty? _pty;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);

    // Defer PTY start to ensure context is available and widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPty();
    });
  }

  void _startPty() {
    final appState = context.read<AppState>();
    final adbPath = appState.adbService.adbPath;

    try {
      // Create the PTY
      _pty = Pty.start(
        adbPath,
        arguments: ['-s', widget.deviceId, 'shell'],
        columns: 80,
        rows: 24,
      );

      // Pipe PTY output to Terminal
      _pty!.output.cast<List<int>>().transform(const Utf8Decoder()).listen((
        text,
      ) {
        _terminal.write(text);
      });

      // Pipe Terminal input to PTY
      _terminal.onOutput = (data) {
        _pty!.write(const Utf8Encoder().convert(data));
      };

      // Handle resize
      _terminal.onResize = (w, h, pw, ph) {
        _pty!.resize(h, w);
      };

      // Handle exit
      _pty!.exitCode.then((code) {
        if (mounted) {
          _terminal.write(
            '\r\nSession execution completed with exit code $code\r\n',
          );
        }
      });
    } catch (e) {
      _terminal.write('Failed to start adb shell: $e\r\n');
    }
  }

  @override
  void dispose() {
    _pty?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;

    return TerminalView(
      _terminal,
      controller: _controller,
      autofocus: true,
      backgroundOpacity: 0.0, // Transparent, will use container background
      textStyle: const TerminalStyle(fontFamily: 'Monospace', fontSize: 12),
      theme: TerminalTheme(
        cursor: theme.accentPrimary,
        selection: theme.accentPrimary.withOpacity(0.3),
        foreground: Colors.white,
        background: Colors.transparent,
        black: Colors.black,
        red: Colors.red,
        green: Colors.green,
        yellow: Colors.yellow,
        blue: Colors.blue,
        magenta: Colors.purple,
        cyan: Colors.cyan,
        white: Colors.white,
        brightBlack: Colors.white24,
        brightRed: Colors.redAccent,
        brightGreen: Colors.greenAccent,
        brightYellow: Colors.yellowAccent,
        brightBlue: Colors.blueAccent,
        brightMagenta: Colors.purpleAccent,
        brightCyan: Colors.cyanAccent,
        brightWhite: Colors.white,
        searchHitBackground: theme.accentPrimary,
        searchHitBackgroundCurrent: theme.accentPrimary,
        searchHitForeground: Colors.black,
      ),
    );
  }
}
