import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('History'),
        titleWidth: 150,
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const Center(
              child: Text('History — Monthly / Weekly / Daily views coming soon'),
            );
          },
        ),
      ],
    );
  }
}
