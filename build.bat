@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  vpn-spike 一键验证：把 Go .so 打进 HAP，装到手机，点按钮看 Add(1,2)
REM  用法：git clone https://github.com/TririLi/vpn-spike.git D:\Tools\vpnspike
REM        D:\Tools\vpnspike\build.bat
REM ============================================================
set REPO=%~dp0
set SRC=D:\Tools\tvbox
set PROJ=D:\Tools\vpntest
set DEVECO=D:\Tools\DevEco\studio
set LOG=%REPO%build.log

echo [1/5] 复制工程 %SRC% -^> %PROJ% > %LOG%
if exist "%PROJ%" rmdir /s /q "%PROJ%"
robocopy "%SRC%" "%PROJ%" /E /XD .hvigor .git build /NFL /NDL /NJH /NJS /NP >> %LOG% 2>&1

echo [2/5] 覆盖 spike 文件 >> %LOG%
if not exist "%PROJ%\entry\src\main\cpp" mkdir "%PROJ%\entry\src\main\cpp"
if not exist "%PROJ%\entry\libs\arm64-v8a" mkdir "%PROJ%\entry\libs\arm64-v8a"
xcopy /E /I /Y "%REPO%app\cpp" "%PROJ%\entry\src\main\cpp" >> %LOG% 2>&1
copy /Y "%REPO%libgoadd.so" "%PROJ%\entry\libs\arm64-v8a\libgoadd.so" >> %LOG% 2>&1
copy /Y "%REPO%app\Index.ets" "%PROJ%\entry\src\main\ets\pages\Index.ets" >> %LOG% 2>&1
copy /Y "%REPO%app\entry-build-profile.json5" "%PROJ%\entry\build-profile.json5" >> %LOG% 2>&1
copy /Y "%REPO%app\entry-oh-package.json5" "%PROJ%\entry\oh-package.json5" >> %LOG% 2>&1

echo [3/5] 编译 >> %LOG%
set DEVECO_SDK_HOME=%DEVECO%\sdk
set PATH=%DEVECO%\tools\node;%DEVECO%\tools\ohpm\bin;%DEVECO%\jbr\bin;%PATH%
cd /d "%PROJ%"
call "%DEVECO%\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=default -p buildMode=debug --no-daemon > "%REPO%hvigor.log" 2>&1
findstr /C:"BUILD SUCCESSFUL" /C:"BUILD FAILED" /C:"Error Message" "%REPO%hvigor.log" >> %LOG%

echo [4/5] 装机 >> %LOG%
set HDC=%DEVECO%\sdk\default\openharmony\toolchains\hdc.exe
"%HDC%" install -r "%PROJ%\entry\build\default\outputs\default\entry-default-signed.hap" >> %LOG% 2>&1

echo [5/5] 启动 >> %LOG%
"%HDC%" shell aa force-stop com.ohos.tvbox >> %LOG% 2>&1
"%HDC%" shell aa start -a EntryAbility -b com.ohos.tvbox >> %LOG% 2>&1

echo ==== 完成，日志：%LOG% ====
type "%LOG%" | findstr /C:"BUILD SUCCESSFUL" /C:"BUILD FAILED" /C:"Error Message" /C:"install bundle" /C:"start ability"
endlocal
