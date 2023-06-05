import 'package:deepfacelab_client/widget/common/open_issue_widget.dart';
import 'package:deepfacelab_client/widget/common/select_theme_widget.dart';
import 'package:deepfacelab_client/widget/installation/installation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SelectableText('Settings'),
      ),
      body: SingleChildScrollView(
        child: Container(
            margin: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SelectThemeWidget(),
                const OpenIssueWidget(),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: InstallationWidget(),
                ),
              ],
            )),
      ),
    );
  }
}
