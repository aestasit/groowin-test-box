:: Ensure C:\Chocolatey\bin is on the path
set /p PATH=<C:\Windows\Temp\PATH

cmd /c choco install 7zip.install
cmd /c choco install windows-sdk-6.1