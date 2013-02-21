classdef TextReporterBase < SummaryReaderBase

properties (Constant)
    WEB_KB          = ParamsManager.WEBKB_CONSTRUCTED;
    NG_20           = ParamsManager.TWENTY_NG_4715   ;
    ENRON_FARMER    = ParamsManager.ENRON_FARMER     ;
    ENRON_KAMINSKI  = ParamsManager.ENRON_KAMINSKI   ;
    REUTERS         = ParamsManager.REUTERS          ;
    AMAZON_3        = ParamsManager.AMAZON_3         ;
    SENTIMENT_5K    = ParamsManager.SENTIMENT_5K     ;
    AMAZON_7        = ParamsManager.AMAZON_7         ;    
end% constant properties

methods (Access = protected)

%% gatherResults_tacoBaseLines

function results = gatherResults_tacoBaseLines(this)
    balanced.key = 'balanced';
    balanced.value = {'0'};
    balanced.shouldMatch = 1;

    num_labeled.key = 'num labeled';
    numLabeledPerGraph = this.numLabeledPerGraphForTables();
    num_labeled.shouldMatch = 1;

    num_iterations.key = 'max iterations';
    num_iterations.value = {'10'};
    num_iterations.shouldMatch = 1;

    labeled_init.key = 'labelled init';        
    labeled_init.shouldMatch = 1;
    labeled_init.value = {'1'};
    
    taco_objective.key = 'TACO objective';
    taco_objective.value = {num2str(CSSLBase.OBJECTIVE_HARMONIC_MEAN)};
    taco_objective.shouldMatch = 1;

    searchProperties = [taco_objective balanced labeled_init num_iterations];

    graph.key = 'graph';
    nlpGraphNames = this.nlpGraphNames();
    graph.shouldMatch = 1;
    numGraphs = length(nlpGraphNames);

%         for table_i=1:length(searchProperties)
    for graph_i = 1:numGraphs
        graph.value = nlpGraphNames(graph_i);
        num_labeled.value = numLabeledPerGraph(graph_i);

        Logger.log(['TextReporterBase::gatherResults_tacoBaseLines. Looking for result on ''' graph.value{1} ''''...
                    ', num_labeled = ' num2str(num_labeled.value{1})]);

        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;

        metricOptimizeByName = MetricProperties.metricOptimizeByName();
        metricRange          = MetricProperties.allMetricsRange();
        
        for metric_ID = metricRange
            optimize_by.value = metricOptimizeByName(metric_ID);
            results{graph_i,metric_ID} = ...
                this.findAlgorithms([searchProperties num_labeled graph optimize_by]); %#ok<AGROW>    
        end
    end
end
    
%% gatherResults_tacoVariants

function results = gatherResults_tacoVariants(this)
    balanced.key = 'balanced';
    balanced.value = {'0'};
    balanced.shouldMatch = 1;

    num_labeled.key = 'num labeled';
    numLabeledPerGraph = this.numLabeledPerGraphForTables();
    num_labeled.shouldMatch = 1;

    num_iterations.key = 'max iterations';
    num_iterations.value = {'10'};
    num_iterations.shouldMatch = 1;

    labeled_init.key = 'labelled init';        
    labeled_init.shouldMatch = 1;
    labeled_init.value = {'1'};
    
    heuristics.key = 'heuristics';
    heuristics.value = {'0'};
    heuristics.shouldMatch = 1;

    algorithm.key = 'Algorithm';
    algorithm.shouldMatch = 1;
    algorithm.value = {CSSLMC.name()};
    
    searchProperties = [balanced labeled_init num_iterations heuristics algorithm];
    
    taco_objective.key = 'TACO objective';
    taco_objective.shouldMatch = 1;

    graph.key = 'graph';
    nlpGraphNames = this.nlpGraphNames();
    graph.shouldMatch = 1;
    numGraphs = length(nlpGraphNames);
    
    TACO_variants_order  = this.TACO_variants_order();
    metricOptimizeByName = MetricProperties.metricOptimizeByName();
    metricRange          = MetricProperties.allMetricsRange(); %[MetricProperties.PRBEP MetricProperties.MACRO_ACC];

    for graph_i = 1:numGraphs
        graph.value       = nlpGraphNames(graph_i);
        num_labeled.value = numLabeledPerGraph(graph_i);

        Logger.log(['TextReporterBase::gatherResults_tacoVariants. Looking for result on ''' graph.value{1} ''''...
                    ', num_labeled = ' num2str(num_labeled.value{1})]);

        optimize_by.key = 'optimize_by';
        optimize_by.shouldMatch = 1;
        
        for metric_ID = metricRange
            optimize_by.value = metricOptimizeByName(metric_ID);
            for TACO_variant_ID = TACO_variants_order
                taco_objective.value = {num2str(TACO_variant_ID)};
                results{graph_i,metric_ID,TACO_variant_ID} = ...
                    this.findEntries([searchProperties num_labeled graph optimize_by taco_objective]); %#ok<AGROW>    
            end
        end
    end
end

end

methods (Static)
    
%% confidenceIntervalFactor

function R = confidenceIntervalFactor()
    R = (1.96 / sqrt(20));
end

%% toConfidenceIntervals

function R = toConfidenceIntervals( stddev )
    confidenceIntervalFactor = TextReporterBase.confidenceIntervalFactor();
    R = confidenceIntervalFactor * stddev ; % 95 confidence intervals.
end

%% nlpGraphIDs

function R = nlpGraphIDs()
    R = [TextReporterBase.WEB_KB ...
         TextReporterBase.NG_20 ...
         TextReporterBase.SENTIMENT_5K ...
         TextReporterBase.REUTERS ...
         TextReporterBase.ENRON_FARMER ...
         TextReporterBase.ENRON_KAMINSKI ...
         TextReporterBase.AMAZON_3 ...
        ];
end

%% nlpGraphNames

function R = nlpGraphNames()
    R = {  'webkb_constructed' , ...
           'twentyNG_4715', ...
           'sentiment_5k' ...
           'reuters_4_topics.tfidf.graph', ...
           'farmer-d.tfidf.graph', ...
           'kaminski-v.tfidf.graph', ...
           'books_dvd_music.tfidf.graph' ...
         };
end

function R = graphNamesForUser()
    R = {  'WebKB' , ...
           '20 News', ...
           'Sentiment' ...
           'Reuters', ...
           'Enron A', ...
           'Enron B', ...
           'Amazon3' ...
         };
end

%% numLabeledPerGraphForTables

function R = numLabeledPerGraphForTables()
    R = { '48' , ...
          '105', ...
          '500' ...
          '48', ...
          '48', ...
          '48', ...
          '35' ...
        };
end

end % private methods
    
end % classdef