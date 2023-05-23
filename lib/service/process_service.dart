import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deepfacelab_client/class/app_state.dart';
import 'package:deepfacelab_client/class/conda_env_list.dart';
import 'package:deepfacelab_client/class/workspace.dart';
import 'package:flutter/cupertino.dart';

class ProcessService {
  Future<String> getCondaPrefix(Workspace? workspace,
      {ValueNotifier<List<String>>? ouputs}) async {
    if (Platform.isWindows) {
      return _getCondaPrefixWindows(ouputs: ouputs, workspace: workspace);
    }
    return _getCondaPrefixLinux(ouputs: ouputs, workspace: workspace);
  }

  Future<String> _getCondaPrefixWindows(
      {ValueNotifier<List<String>>? ouputs, Workspace? workspace}) async {
    var setEnv = File("${store.state.storage?.deepFaceLabFolder}/setenv.bat")
        .readAsStringSync()
        .replaceAll('SET INTERNAL=%~dp0',
        'SET INTERNAL=${store.state.storage?.deepFaceLabFolder}')
        .replaceAll('SET INTERNAL=%INTERNAL:~0,-1%\n',
        '');
    if (workspace != null) {
      setEnv = setEnv.replaceAll('SET WORKSPACE=%INTERNAL%\\..\\workspace',
          'SET WORKSPACE=${workspace.path}');
    }
    return setEnv;
  }

  Future<String> _getCondaPrefixLinux(
      {ValueNotifier<List<String>>? ouputs, Workspace? workspace}) async {
    String condaInit =
        (await Process.run('conda', ['init', '--verbose', '-d'])).stdout;
    String? match = RegExp(r'initialize[\s\S]*?initialize', multiLine: true)
        .firstMatch(condaInit)
        ?.group(0);
    Iterable<String>? results = match?.split('\n');
    results = results
        ?.where((e) => e.startsWith('+'))
        .map((e) => e.substring(1))
        .where((e) => e.startsWith('#') == false);
    // https://developer.nvidia.com/rdp/cudnn-archive
    // https://developer.nvidia.com/cuda-toolkit-archive
    // https://www.tensorflow.org/install/source#gpu
    // https://repo.anaconda.com/pkgs/main/linux-64/
    String pythonVersion = '3.7';
    String cudnnVersion = '7.6.5';
    String cudatoolkitVersion = '10.1.243';
    String condaEnvName =
        'deepFaceLabClient_python${pythonVersion}_cudnn${cudnnVersion}_cudatoolkit$cudatoolkitVersion';
    CondaEnvList condaEnvList = CondaEnvList.fromJson(jsonDecode(
        (await Process.run('conda', ['env', 'list', '--json'])).stdout));
    // https://stackoverflow.com/questions/59343470/type-dynamic-dynamic-is-not-a-subtype-of-type-dynamic-bool-of-tes
    // https://stackoverflow.com/questions/52354195/list-firstwhere-bad-state-no-element
    if (condaEnvList.envs.firstWhere((env) => env.contains(condaEnvName),
        orElse: () => "") ==
        "") {
      if (ouputs != null) {
        ouputs.value = [
          ...ouputs.value,
          'conda create -n $condaEnvName -c main python=$pythonVersion cudnn=$cudnnVersion cudatoolkit=$cudatoolkitVersion'
        ];
      }
      (await Process.run('conda', [
        'create',
        '-n',
        condaEnvName,
        '-c',
        'main',
        'python=$pythonVersion',
        'cudnn=$cudnnVersion',
        'cudatoolkit=$cudatoolkitVersion'
      ]));
    }
    String result =
        "${results?.join("\n") ?? ""}\nconda activate $condaEnvName";
    if (ouputs != null) {
      ouputs.value = [...ouputs.value, result];
    }
    return result.trim();
  }
}
