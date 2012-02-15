classdef Splitter
    %SPLITTER Summary of this class goes here
    %   Detailed explanation goes here

properties
    m_graph;
end
    
methods
    
    function this = Splitter( graph )
        this.m_graph = graph;
    end
    
    %% create
    
    function R = create( this, balancedFolds, numFolds )
        if (balancedFolds)
            R = this.splitBalanced(numFolds);
        else
            R = this.split(numFolds);
        end
    end
    
    %% split
    
    function R = split(this, numFolds)
        numVertices = this.m_graph.numVertices();
        folds = Splitter.randomSplit( 1:numVertices, numFolds );
        R = TrunsductionSet( folds );
    end
    
    %% splitBalanced
    
    function R = splitBalanced(this, numFolds)
        availabelLabels = this.m_graph.availabelLabels();
        folds = [];
        %allDiscarded = [];
        for currentLabel = availabelLabels;
            verticesForCurrentLabel = this.m_graph.verticesForLabel( currentLabel );
            foldsPerLabel = Splitter.randomSplit...
                ( verticesForCurrentLabel, numFolds );
            folds = [folds foldsPerLabel]; %#ok<AGROW>
            %allDiscarded = [allDiscarded;discarded]; %#ok<AGROW>
            %folds = horzcat(folds, foldsPerLabel); 
        end
        R = TrunsductionSet( folds );
    end    
end

methods (Static)
    %% randomSplit
    
    function folds = randomSplit( data, numGroups )
        dataSize    = numel(data);                      %# get number of elements
        groupSize   = floor(dataSize/numGroups);       %# assuming here that it's neatly divisible 
        tailSize    = mod(dataSize,numGroups);
        % maybe do something with the tail
        % discarded   = data( end-tailSize +1:end );
        withoutTail = data(1:end-tailSize);
        permuted    = withoutTail(randperm(length(withoutTail)));
        folds       = reshape(permuted, numGroups, groupSize);
        groupsOrder = randperm(numGroups);
        folds       = folds(groupsOrder,:);
    end  
end
    
end

