set sasbaseard=%cd%
echo|set /p="%%let sasbaseard = " >sasbaseard.sas
echo %cd%; >>sasbaseard.sas
