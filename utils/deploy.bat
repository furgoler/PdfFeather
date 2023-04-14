:: https://doc.qt.io/qt-6/windows-deployment.html

:: Get current dir of this bat file
set mypath=%~dp0

:: Path to output deployment folder
set outpath=%mypath%..\..\pdffeather-bin

:: QML app files location and EXE app
set qmlpath=%mypath%..
set apppath=%mypath%..\..\build-pdffeather-64bit\release

:: QPdf C++ Library bin
set qpdfpath=%mypath%..\3rdparty\qpdf-11.3.0-msvc64\bin

:: WinDLL Path
set windllpath=C:\Windows\SysWOW64

:: windeployqt
windeployQT --dir "%outpath%" --release --qmldir "%qmlpath%" "%apppath%"\pdffeather.exe

:: Copy EXE and external dependencies
xcopy /Y "%apppath%"\pdffeather.exe "%outpath%"
xcopy /Y "%qpdfpath%"\qpdf29.dll "%outpath%"

:: Copy MSVC DLL
xcopy /Y "%windllpath%"\vcruntime140.dll "%outpath%"
xcopy /Y "%windllpath%"\msvcp140.dll "%outpath%"
xcopy /Y "%windllpath%"\msvcp140_?.dll "%outpath%"
xcopy /Y "%windllpath%"\vccorlib140.dll "%outpath%"
