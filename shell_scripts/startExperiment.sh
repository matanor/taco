
outputDir=/u/matanorb/experiments/webkb/results
folderName=2012_03_19_02_webkb_amar_balanced_all_heuristics_all_init_mode_all_optimized_added_AM
runName=CSSLMC
outputFile=$outputDir/$folderName/output.txt
errorFile=$outputDir/$folderName/error.txt
logFile=$outputDir/$folderName/matlab.log
codeRoot=/u/matanorb/matlab_async
workingDirectory=$codeRoot/Experiments
startDirectory="$(pwd)"

echo codeRoot = $codeRoot
echo workingDirectory = $workingDirectory
echo startDirectory = $startDirectory
echo outputDir = $outputDir
echo folderName = $folderName
echo runName = $runName
echo outputFile = $outputFile
echo errorFile = $errorFile

mkdir $outputDir/$folderName
cd $workingDirectory
echo currentDirectory = "$(pwd)"
echo "matlab -nodesktop -r "\""runOnOdin('$folderName','$codeRoot')"\"" "
matlab -nodesktop -r "runOnOdin('$folderName','$codeRoot');quit;" -logfile $logFile
cd $startDirectory

#echo qsub -N $runName -wd $codeRoot/Experiments -q all.q -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""runOnOdin('$folderName','$codeRoot')"\"" -logfile $logFile"
#qsub -N $runName -wd $codeRoot/Experiments -q all.q -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""runOnOdin('$folderName','$codeRoot')"\"" -logfile $logFile"
#qsub -N $runName -cwd -q all.q -pe matlablocal <number_of_cpu_needed> -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""RunOnOdin"\"" -logfile matlab.log"
