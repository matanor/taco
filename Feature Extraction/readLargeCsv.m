function result = readLargeCsv()

tic;
fid=fopen('tfidf.csv','rt');

curLine=fgetl(fid); %read one line at a time
numTokens = length(strfind(curLine, ','))+1;

result = [];
rowInd=1; %you could use a FOR loop instead..
% & (rowInd < 5)
while((curLine~=-1) )
    if ( mod(rowInd, 10) == 0)
        display(rowInd);
    end;
    numericLine = zeros(1,numTokens);
    delim_indexes = strfind(curLine, ',');
    delim_indexes = [0 delim_indexes length(curLine)];
    %numTokens = length(delim_indexes) - 1;
    for i=1:numTokens
        startPos = delim_indexes(i) + 1;
        endPos   = delim_indexes(i+1)-1;
        token = curLine(startPos:endPos);
        if ( strcmp(token, '0.0') ~= 1)
            % strcmp is much faster then str2double
            % so its worth checking for 0 using it.
            numericValue = str2double(token);
            numericLine(i) = numericValue;
        end;
        
    end
    sparseLine = sparse(numericLine);
    result = [result;sparseLine];
    curLine = fgetl(fid);
    rowInd = rowInd + 1;
end

fclose(fid);
toc;

end
