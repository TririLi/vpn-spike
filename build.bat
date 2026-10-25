@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  vpn-spike 一键验证（原地打补丁模式，不复制工程）
REM  用法：D:\Tools\vpnspike\build.bat
REM  跑完会自动还原被替换的三个文件
REM ============================================================
set REPO=%~dp0
set PROJ=D:\Tools\tvbox
set BAK=%REPO%_bak
set DEVECO=D:\Tools\DevEco\studio
set LOG=%REPO%build.log
set HDC=%DEVECO%\sdk\default\openharmony\toolchains\hdc.exe

echo ==== start %TIME% ==== > %LOG%

echo [1/6] 备份原始文件 >> %LOG%
if not exist "%BAK%" mkdir "%BAK%"
copy /Y "%PROJ%\entry\src\main\ets\pages\Index.ets" "%BAK%\Index.ets" >> %LOG% 2>&1
copy /Y "%PROJ%\entry\build-profile.json5" "%BAK%\build-profile.json5" >> %LOG% 2>&1
copy /Y "%PROJ%\entry\oh-package.json5" "%BAK%\oh-package.json5" >> %LOG% 2>&1

echo [2/6] 注入 spike 文件 >> %LOG%
if not exist "%PROJ%\entry\src\main\cpp" mkdir "%PROJ%\entry\src\main\cpp"
if not exist "%PROJ%\entry\libs\arm64-v8a" mkdir "%PROJ%\entry\libs\arm64-v8a"
xcopy /E /I /Y "%REPO%app\cpp" "%PROJ%\entry\src\main\cpp" >> %LOG% 2>&1
copy /Y "%REPO%libgoadd.so" "%PROJ%\entry\libs\arm64-v8a\libgoadd.so" >> %LOG% 2>&1
copy /Y "%REPO%app\Index.ets" "%PROJ%\entry\src\main\ets\pages\Index.ets" >> %LOG% 2>&1
copy /Y "%REPO%app\entry-build-profile.json5" "%PROJ%\entry\build-profile.json5" >> %LOG% 2>&1
copy /Y "%REPO%app\entry-oh-package.json5" "%PROJ%\entry\oh-package.json5" >> %LOG% 2>&1

echo [3/6] 编译 >> %LOG%
set DEVECO_SDK_HOME=%DEVECO%\sdk
set PATH=%DEVECO%\tools\node;%DEVECO%\tools\ohpm\bin;%DEVECO%\jbr\bin;%PATH%
cd /d "%PROJ%"
call "%DEVECO%\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=default -p buildMode=debug --no-daemon > "%REPO%hvigor.log" 2>&1
findstr /C:"BUILD SUCCESSFUL" /C:"BUILD FAILED" /C:"Error Message" /C:"error:" "%REPO%hvigor.log" >> %LOG%

echo [4/6] 装机 >> %LOG%
"%HDC%" install -r "%PROJ%\entry\build\default\outputs\default\entry-default-signed.hap" >> %LOG% 2>&1

echo [5/6] 启动 >> %LOG%
"%HDC%" shell aa force-stop com.ohos.tvbox >> %LOG% 2>&1
"%HDC%" shell aa start -a EntryAbility -b com.ohos.tvbox >> %LOG% 2>&1

echo [6/6] 还原原始文件 >> %LOG%
if /I "%1"=="/keep" (
  echo 检测到 /keep，跳过还原（IDE 里可直接打开该工程看到测试页） >> %LOG%
  goto skiprestore
)
copy /Y "%BAK%\Index.ets" "%PROJ%\entry\src\main\ets\pages\Index.ets" >> %LOG% 2>&1
copy /Y "%BAK%\build-profile.json5" "%PROJ%\entry\build-profile.json5" >> %LOG% 2>&1
copy /Y "%BAK%\oh-package.json5" "%PROJ%\entry\oh-package.json5" >> %LOG% 2>&1
:skiprestore

echo ==== done %TIME% ==== >> %LOG%
type "%LOG%" | findstr /C:"BUILD SUCCESSFUL" /C:"BUILD FAILED" /C:"Error Message" /C:"error:" /C:"install bundle" /C:"start ability" /C:"done"
endlocal
