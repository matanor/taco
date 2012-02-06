
runName=test
outputFile=1.out
errorFile=1.err

echo runName = $runName
echo outputFile = $outputFile
echo errorFile = $errorFile

qsub -N $runName -wd /u/matanorb/matlab/Experiments -q all.q -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""runOnOdin('2012_02_06')"\"" -logfile matlab.log"


#qsub -N $runName -cwd -q all.q -pe matlablocal <number_of_cpu_needed> -b y -o $outputFile -e $errorFile "matlab -nodesktop -r "\""RunOnOdin"\"" -logfile matlab.log"
#\'/u/matanorb/experiments/results/2012_02_06\'
