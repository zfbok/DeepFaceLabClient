import 'dart:io';

import 'package:deepfacelab_client/class/start_process.dart';
import 'package:deepfacelab_client/widget/common/divider_with_text.dart';
import 'package:deepfacelab_client/widget/common/open_issue_widget.dart';
import 'package:deepfacelab_client/widget/common/start_process_widget.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class RequirementWidgetLinux extends HookWidget {
  RequirementWidgetLinux({Key? key}) : super(key: key);
  String homeDirectory = (Platform.environment)['HOME'] ?? "/";

  @override
  Widget build(BuildContext context) {
    var requirements = useState<Map<String, bool>?>(null);
    var requirementOk = useState<bool?>(null);
    var loading = useState<bool>(false);
    var startProcesses = useState<List<StartProcess>>([]);
    var condaInstallFolder = useState<String>(homeDirectory);
    var whoami = useState<String?>(null);

    updateRequirements() async {
      Map<String, bool> newRequirements = {
        'hasWget': (await Process.run('which', ['wget'])).stdout != '',
        'hasBash': (await Process.run('which', ['bash'])).stdout != '',
        'hasGit': (await Process.run('which', ['git'])).stdout != '',
        'hasFfmpeg': (await Process.run('which', ['ffmpeg'])).stdout != '',
        'hasConda': (await Process.run('which', ['conda'])).stdout != '',
      };
      requirements.value = newRequirements;
      List<StartProcess> newStartProcesses = [];
      if (newRequirements['hasWget'] == false ||
          newRequirements['hasBash'] == false ||
          newRequirements['hasGit'] == false ||
          newRequirements['hasFfmpeg'] == false) {
        newStartProcesses.add(StartProcess(executable: 'pkexec', arguments: [
          'bash',
          '-c',
          """
apt install \\
${newRequirements['hasBash'] == false ? "bash \\" : ""}
${newRequirements['hasWget'] == false ? "wget \\" : ""}
${newRequirements['hasGit'] == false ? "git \\" : ""}
${newRequirements['hasFfmpeg'] == false ? "ffmpeg \\" : ""}
-y
          """
        ]));
      }
      if (newRequirements['hasConda'] == false) {
        String miniCondaFolder = "${condaInstallFolder.value}/miniconda";
        newStartProcesses.add(StartProcess(executable: 'bash', arguments: [
          '-c',
          """\\
rm -f $miniCondaFolder.sh && \\
rm -rf $miniCondaFolder && \\
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $miniCondaFolder.sh && \\
bash $miniCondaFolder.sh -b -p $miniCondaFolder && \\
rm $miniCondaFolder.sh
"""
        ]));
        String binMiniConda = "$miniCondaFolder/bin";
        newStartProcesses.add(StartProcess(executable: 'pkexec', arguments: [
          'bash',
          '-c',
          """\n
if ! grep -q '$binMiniConda' /etc/environment; then
  sed -i '\$s/.\$/:${binMiniConda.replaceAll('/', '\\/')}"/' /etc/environment
fi
          """
        ]));
      }
      startProcesses.value = newStartProcesses;
      whoami.value = (await Process.run('whoami', [])).stdout;
      requirementOk.value = requirements.value?.entries
          .map<bool>((e) => e.value)
          .reduce((value, element) => value && element);
    }

    onUpdateRequirements() async {
      loading.value = true;
      await updateRequirements();
      loading.value = false;
    }

    selectFolder() {
      FilesystemPicker.openDialog(
        title: 'Save to folder',
        context: context,
        rootDirectory: Directory("/"),
        directory: Directory(condaInstallFolder.value),
        fsType: FilesystemType.folder,
        pickText: 'Validate (use this folder to install conda)',
      ).then((value) {
        return condaInstallFolder.value = value ?? condaInstallFolder.value;
      });
    }

    onInstallationDone() {
      if(requirements.value!['hasConda'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.background,
          content: const SelectableText('Please restart your computer to load conda in your PATH', style: TextStyle(color: Colors.white),),
          duration: const Duration(days: 1),
        ));
      }
      onUpdateRequirements();
    }

    useEffect(() {
      updateRequirements();
    }, [condaInstallFolder.value]);

    return (requirements.value != null)
        ? Container(
            margin: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  selectable: true,
                  data: """# Requirements

${requirements.value!['hasWget'] == true ? "✅ `wget`" : "❌ `wget` was not found by running command `which wget`, just run `sudo apt install wget -y` to install it"}

${requirements.value!['hasBash'] == true ? "✅ `bash`" : "❌ `bash` was not found by running command `which bash`, just run `sudo apt install bash -y` to install it"}

${requirements.value!['hasGit'] == true ? "✅ `git`" : "❌ `git` was not found by running command `which git`, just run `sudo apt install git -y` to install it"}

${requirements.value!['hasFfmpeg'] == true ? "✅ `ffmpeg`" : "❌ `ffmpeg` was not found by running command `which ffmpeg`, just run `sudo apt install ffmpeg -y` to install it"}
                  """,
                ),
                requirements.value!['hasConda'] == true
                    ? Container(
                        margin: const EdgeInsets.only(top: 10.0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "✅ ",
                              ),
                              TextSpan(
                                  text: "conda",
                                  style: TextStyle(
                                    background: Paint()..color = Colors.white10,
                                  )),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(top: 10.0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "❌ ",
                              ),
                              TextSpan(
                                  text: "conda",
                                  style: TextStyle(
                                    background: Paint()..color = Colors.white10,
                                  )),
                              const TextSpan(
                                text: " was not found by running command ",
                              ),
                              TextSpan(
                                  text: "which conda",
                                  style: TextStyle(
                                    background: Paint()..color = Colors.white10,
                                  )),
                              const TextSpan(
                                text: ", to install ",
                              ),
                              TextSpan(
                                  text: "conda",
                                  style: TextStyle(
                                    background: Paint()..color = Colors.white10,
                                  )),
                              TextSpan(
                                text: ' follow the tutorial',
                                style: const TextStyle(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                        Uri.parse(
                                            'https://docs.conda.io/projects/conda/en/latest/user-guide/install/'),
                                        mode: LaunchMode.platformDefault);
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                if (requirementOk.value == false) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 50.0),
                    child: const MarkdownBody(selectable: true, data: """
## Install by yourself
                    
You need to install the missing packages, and add it to your `PATH` if necessary

- You can do it yourself and then click on `Recheck my requirements`.
- Or you can click on `Install for me` and DeepFaceLabClient will try to install all missing packages for you.
"""),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 30.0, bottom: 30.0),
                    child: ElevatedButton.icon(
                      onPressed: loading.value ? null : onUpdateRequirements,
                      icon: loading.value
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const SizedBox.shrink(),
                      label: const Text('Recheck my requirements'),
                    ),
                  ),
                  DividerWWithTextWidget(text: "OR"),
                  Container(
                      margin: const EdgeInsets.only(top: 30.0, bottom: 30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MarkdownBody(selectable: true, data: """
## Let DeepFaceLabClient try to install
"""),
                          if (requirements.value!['hasConda'] == false) ...[
                            Row(
                              children: [
                                MarkdownBody(selectable: true, data: """
`conda` will be install in this folder `${condaInstallFolder.value}`
"""),
                                IconButton(
                                  icon: const Icon(Icons.folder),
                                  splashRadius: 20,
                                  onPressed: selectFolder,
                                ),
                              ],
                            ),
                            MarkdownBody(selectable: true, data: """
please click on the folder icon to change the location (you must have write permission to this folder as user `${whoami.value}`)

Note that DeepFaceLabClient will add a path in your `/etc/environment` file to add `conda` in your `PATH`,
when the installation is done you will need to restart your computer.
"""),
                          ],
                          Container(
                            margin: const EdgeInsets.only(top: 10.0),
                            child: StartProcessWidget(
                              label: "Install for me",
                              startProcesses: startProcesses.value,
                              callback: onInstallationDone,
                            ),
                          ),
                        ],
                      )),
                  Container(
                      margin: const EdgeInsets.only(top: 10.0),
                      child: OpenIssueWidget()),
                ]
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}
