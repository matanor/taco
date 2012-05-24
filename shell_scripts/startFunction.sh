
outputDir=/u/matanorb/experiments/results/
folderName=$2
resultsDirectory=$outputDir$folderName
logFile=$resultsDirectory/matlab.log
codeRoot=$3
workingDirectory=$codeRoot/Experiments
startDirectory="$(pwd)"

echo codeRoot = $codeRoot
echo workingDirectory = $workingDirectory
echo startDirectory = $startDirectory
echo outputDir = $outputDir
echo resultsDirectory = $resultsDirectory
echo folderName = $folderName
echo logFile = $logFile

mkdir $resultsDirectory
cd $workingDirectory
echo currentDirectory = "$(pwd)"
echo "matlab -nodesktop -r "\""$1('$resultsDirectory','$codeRoot')"\"" "
matlab -nodesktop -r "$1('$resultsDirectory','$codeRoot');quit;" -logfile $logFile
cd $startDirectory
