import 'dart:io';

void main() async {
  print('--- Power Smart Uninstaller ---');
  print('This will remove the application files from this folder.');
  print('Do you want to proceed? (y/n)');

  // Simple CLI confirmation
  var input = stdin.readLineSync()?.toLowerCase();
  if (input != 'y') {
    print('Uninstallation cancelled.');
    exit(0);
  }

  print('Uninstalling...');

  try {
    // 1. Give the main app time to close if it's open
    await Future.delayed(Duration(seconds: 1));

    // 2. Get the current directory (where the uninstaller is)
    final dir = Directory.current;
    print('Removing files in: ${dir.path}');

    // 3. Create a temporary batch file to delete everything including this EXE
    // This is the standard way a Windows EXE deletes itself.
    final cleanupScript = File('cleanup_uninstall.bat');
    final scriptContent =
        '''
@echo off
timeout /t 2 /nobreak > nul
echo Deleting application files...
cd /d "${dir.path}"
for /d %%p in (*) do rmdir /s /q "%%p"
del /q *.*
echo Uninstallation Complete!
pause
(goto) 2>nul & del "%~f0"
''';

    await cleanupScript.writeAsString(scriptContent);

    print('Cleanup script created. Starting final cleanup...');
    print('The terminal will close and a new window will finish the process.');

    // 4. Run the batch file and exit
    Process.run('cmd', ['/c', 'start', 'cleanup_uninstall.bat']);
    exit(0);
  } catch (e) {
    print('Error during uninstallation: $e');
    exit(1);
  }
}
