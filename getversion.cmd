:: Script to get the current Git version number and write it to a file..
:: Usage:
:: getversion.cmd <tmpfilename> <verfilename>
:: where <tmpfilename> is the name of the temporary file in which to write the version number.
:: and <verfilename> is the name of the permanent file in which the version number is kept.
::
:: Author: Karl Wallendszus
::
:: 2020-02-20 First version

::@echo off

:: Write Git version number to temporary file
git describe --tags >%~1
if %ERRORLEVEL% neq 0 ( goto :tidy )

:: If permanent file does not exist use temporary file
if not exist %~2 ( goto :rentmp )

:: If permanent file is empty, replace it with temporary file
if %~z2 LEQ 0 ( goto :delperm )

:: If temporary file is not empty, replace permanent file with it
if %~z1 GTR 0 ( goto :delperm ) else ( goto :tidy )

:: Delete and rename as appropriate
:delperm
del %~2
:rentmp
ren %~1 %~2

:: Delete temporary file if it still exists
:tidy
if exist %~1 ( del %~1 )
