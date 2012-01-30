classdef KnnClassifier
    %KNNCLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties  (SetAccess=public, GetAccess=protected)
        m_W;
        m_correctLabels;
        m_K;
    end
    
    methods (Static)
        function r = createAndRun(graph, K)
            kc = KnnClassifier;
            kc.m_W = graph.weights;
            kc.m_correctLabels = graph.labels;
            kc.m_K = K;
            r = kc.run();
            
            numMistakes = sum( r ~= graph.labels);
            
            t = [   'Knn Classifier (supervised). '...
                    'numMistakes = ' num2str(numMistakes)];
            figure('name',t); 
            hold on; 
            title(t);
            scatter(1:length(r), r, 'r'); 
            plot(graph.labels); 
            hold off;
        end
    end
    
    methods
        function r = run(this)
            numVertices = size(this.m_W, 1);
            availableLabels = unique(this.m_correctLabels).';
            numLabels = length(availableLabels);
            prediction = zeros(numVertices, 1);
            w_nn = knn( this.m_W, this.m_K);
            for vertex_i=1:numVertices
                neighbours = getNeighbours(w_nn, vertex_i);
                neighbours.labels = this.m_correctLabels(neighbours.indices);
                scores = zeros(numLabels, 1);
                label_i = 1;
                for label_value=availableLabels
                    score = sum( neighbours.labels == label_i );
                    scores(label_i) = score;
                    label_i = label_i + 1;
                end
                [~, predicion_index] = max(scores);
                prediction(vertex_i) = availableLabels(predicion_index);
            end
            r = prediction;
        end
    end
    
end

