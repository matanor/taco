function createNumericLabels( labelsFileName )
%CREATENUMERICLABELS Summary of this function goes here
%   Detailed explanation goes here

    inputFileID        = fopen(labelsFileName,'r');
    [pathstr, name, ~] = fileparts(labelsFileName);
    outputFileID       = fopen([pathstr '\' name '.numeric.txt'],'w');
    mappingFileID      = fopen([pathstr '\' name '.mapping.txt'],'w');
    nextNumericLabel = 1;
    labelNameToNumbaerTable = containers.Map;
    EOF = -1;
    finished = 0;
    while ~finished
        line = fgets(inputFileID);
        if isempty(line) ||  (isnumeric(line) && line == EOF)
            finished = 1;
        else
            line(line == '"') = [];
            line = strtrim(line);
            if labelNameToNumbaerTable.isKey( line )
                numericLabelValue = labelNameToNumbaerTable( line );
            else
                labelNameToNumbaerTable(line) = nextNumericLabel ;
                fprintf(mappingFileID,'%s -> %s\n', line, num2str(nextNumericLabel));
                numericLabelValue = nextNumericLabel;
                nextNumericLabel = nextNumericLabel + 1;
            end
            fprintf(outputFileID, '%s\n', num2str(numericLabelValue));
        end
    end
    fclose(inputFileID);
    fclose(outputFileID);
    fclose(mappingFileID);
end

