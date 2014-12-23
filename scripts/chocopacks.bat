:: Ensure path in not null for newly open shell window
set /p PATH=<C:\Windows\Temp\PATH

:: Install all the things
cmd /c c:\ProgramData\chocolatey\bin\choco install 7zip.install
cmd /c c:\ProgramData\chocolatey\bin\choco install windows-sdk-6.1