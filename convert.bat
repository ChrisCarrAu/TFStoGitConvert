@echo off

rem %1 = subfolder under /TeamProjectRootFolder (defined below) in TFS
rem %2 = TFS label to retrieve
rem %3 = Git Tag to apply to the code retrieved from TFS by label

echo TFS to Git Label Migration

IF EXIST working\.git GOTO start

echo Create a working folder named "working" and initialise an empty Git repository in it.
goto exit
 
:start

set outfile=../%~3.out
set TeamProjectRootFolder=$/[TeamProjectRootFolder]
set TeamProjectCollectionUrl=[TeamProjectCollectionUrl]

echo ----------------------------------------------------------
echo CONVERTING TFS to Git on label %2...

rem clear working folder
cd working
echo Clearing out work folders from last pass...
IF EXIST "[Folder1]" rd "[Folder1]" /s /q > %outfile%
IF EXIST "[Folder2]" rd "[Folder2]" /s /q >> %outfile%
IF EXIST "[Foldern]" rd "[Foldern]" /s /q >> %outfile%

rem Get the source from TFS by label 
echo Connecting to %TeamProjectCollectionUrl% as MyWorkspace
tf workspace /new /noprompt /s:%TeamProjectCollectionUrl% MyWorkspace >> %outfile%
if errorlevel 1 goto tferror
echo  MyWorkspace connected

echo Mapping MyWorkspace to TFS
tf workfold /map "%TeamProjectRootFolder%/%~1" . >> %outfile%
if errorlevel 1 goto tferror
echo  MyWorkspace mapped to TFS

echo Retrieving Source from TFS by label %2
tf get * /r /version:"L%~2" >> %outfile%
if errorlevel 1 goto tferror
echo  Source retrieved from TFS

echo Deleting MyWorkspace
tf workspaces /collection:%TeamProjectCollectionUrl% >> %outfile%
tf workspace /delete /noprompt MyWorkspace >> %outfile%
if errorlevel 1 goto tferror
echo  MyWorkspace deleted

goto gitinit

:tferror
echo ************************************************************
echo *                                                          *
echo *         ERROR IN TF EXPORT - PROCESSING HALTED           *
echo *                                                          *
echo ************************************************************
pause
goto exitworking

rem git init
:gitinit
echo Creating readme.cmd
echo #%~1 > readme.md
echo ##%~2 >> readme.md
echo. >> readme.md

for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%b-%%a %time%) 
echo Created on %mydate% >> readme.md
echo  readme.cmd created

echo Copying .gitignore
copy ..\.gitignore .

echo Committing source to local Git repository
git add -A && git commit -m "Migrated changesets from TFS with label %~2" >> %outfile%
git tag -a "%3" -m "Imported from label %~2" >> %outfile%
echo  source committed

echo TFS to Git on label %2 conversion complete...
echo ----------------------------------------------------------

:exitworking

cd..

:exit

rem pause
