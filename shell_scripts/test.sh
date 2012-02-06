
outputDir=/u/matanorb/experiments/webkb/results
folderName=2012_02_06_03_graph_heuristics_1
runName=CSSLMC
outputFile=$outputDir/$folderName/output.txt
errorFile=$outputDir/$folderName/error.txt
logFile=$outputDir/$folderName/matlab.log

echo outputDir = $outputDir
echo folderName = $folderName
echo runName = $runName
echo outputFile = $outputFile
echo errorFile = $errorFile

mkdir $outputDir/$folderName
echo qsub -N $runName -wd /u/matanorb/matlab/Experiments -q all.q -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""runOnOdin('$folderName')"\"" -logfile $logFile"
qsub -N $runName -wd /u/matanorb/matlab/Experiments -q all.q -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""runOnOdin('$folderName')"\"" -logfile $logFile"

#qsub -N $runName -cwd -q all.q -pe matlablocal <number_of_cpu_needed> -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""RunOnOdin"\"" -logfile matlab.log"
