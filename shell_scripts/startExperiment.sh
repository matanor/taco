
outputDir=/u/matanorb/experiments/results/
folderName=2012_04_05_01_sentiment_no_random_seed_fixed_labeled_selection
resultsDirectory=$outputDir$folderName
logFile=$resultsDirectory/matlab.log
codeRoot=/u/matanorb/matlab_async
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
echo "matlab -nodesktop -r "\""runOnOdin('$resultsDirectory','$codeRoot')"\"" "
matlab -nodesktop -r "runOnOdin('$resultsDirectory','$codeRoot');quit;" -logfile $logFile
cd $startDirectory
