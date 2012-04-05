
outputDir=/u/matanorb/experiments/webkb/results
folderName=2012_04_05_01_sentiment_no_random_seed_fixed_labeled_selection
logFile=$outputDir/$folderName/matlab.log
codeRoot=/u/matanorb/matlab_async
workingDirectory=$codeRoot/Experiments
startDirectory="$(pwd)"

echo codeRoot = $codeRoot
echo workingDirectory = $workingDirectory
echo startDirectory = $startDirectory
echo outputDir = $outputDir
echo folderName = $folderName

mkdir $outputDir/$folderName
cd $workingDirectory
echo currentDirectory = "$(pwd)"
echo "matlab -nodesktop -r "\""runOnOdin('$folderName','$codeRoot')"\"" "
matlab -nodesktop -r "runOnOdin('$folderName','$codeRoot');quit;" -logfile $logFile
cd $startDirectory
