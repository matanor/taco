classdef MainClass < handle
    %CLASS1 Summary of this class goes here
    %   Detailed explanation goes here
    % http://stackoverflow.com/questions/106086/in-matlab-can-a-class-method-act-as-a-uicontrol-callback-without-being-public
    
    properties (Access=public)
        %graph;
        m_showNumericResults;
        m_showEdgeWeights;
        m_showLegend;
        m_isCalcObjective;
        m_stayInStateProbability;
    end

    properties (Access=private)
        graph;
        figureHandle;
        algorithm_result;
        plotInfo;
        
        numIterations;
        iterationsUI;
        
        currentIteration;
        currentIterationUI;
        
        alpha;
        beta;
        labeledConfidence;
        zeta;
        leftButtonDownPosition;
        algorithmType;
        mu2;
        mu3;
%         rightButtonDownPosition;
    end

%********************** PUBLIC ***************************

methods (Access = public)
    function this = MainClass() % Constructor
        this.numIterations = 100;
        this.beta = 1;
        this.alpha = 1;
        this.zeta = 1;
        this.mu2 = 1;
        this.mu3 = 1;
        this.labeledConfidence = 0.1;
        this.algorithmType = CSSL.name();
        this.m_showEdgeWeights = 1;
        this.m_showNumericResults = 1;
        this.m_showLegend = 1;
        this.m_isCalcObjective = 1;
        this.m_stayInStateProbability = 0.1;
    end

    %% set_graph
    
    function set_graph( this, value )
        this.graph = value;
    end

    %% set_graphFromStruct
    
    function set_graphFromStruct( this, graphStruct )
        this.graph = Graph;
        this.graph.loadFromStruct(graphStruct);
    end

    %% set_numIterations
    
    function set_numIterations(this, value)
        this.numIterations = value;
        set(this.iterationsUI, 'String', num2str( value ) );
    end

    %% set_currentIteration
    
    function set_currentIteration(this, value)
        this.currentIteration = value;
        set(this.currentIterationUI, 'String', num2str( value ) );
    end

    %% runAlgorithm

    function runAlgorithm(this)   
        Logger.log( ['algorithm type = ' this.algorithmType ] );
        if (strcmp( this.algorithmType,LP.name() ) == 1)
            this.runLP();
        elseif (strcmp( this.algorithmType,CSSLMC.name() ) == 1)
            this.runCSSLMC();
        elseif (strcmp( this.algorithmType,CSSL.name() ) == 1)               
            this.runCSSL();
        elseif (strcmp( this.algorithmType,CSSLMCF.name() ) == 1)
            this.runCSSLMCF();
        elseif (strcmp( this.algorithmType,MAD.name() ) == 1)
            this.runMAD();
        elseif (strcmp( this.algorithmType,AM.name() ) == 1)
            this.runAM();
        else
            Logger.log('runAlgorithm::Error. unknown algorithm');
        end
    end

    %% plotGraph

    function plotGraph(this, iter_i)

        Logger.log(['plotGraph: ' num2str(iter_i)]);
        if (isempty( this.figureHandle ) )
            Logger.log('Creating figure...');
            this.figureHandle  = this.createFigureToolbar();
            this.createPlotInfo();
            this.addParamsUI();
        end

        this.plotInfo.Edges = MainClass.createEdges(this.graph.weights());

        newplot;
        this.doPlot( this.plotInfo.Edges, iter_i );

        this.addVerticesContextMenu();
        this.addEdgesContextMenu();

        this.set_currentIteration( iter_i );

        drawnow expose;
    end

end % public methods

%********************** Private Event Handlers ***************************

methods (Access = private)

    %% back
    
    function back(this, ~, ~)
        if (this.currentIteration > 1)
            plotGraph(this, this.currentIteration - 1);
        end
        Logger.log('back');
    end
    
    %% forward

    function forward(this, ~, ~)
        if (this.currentIteration < this.numIterations)
            plotGraph(this, this.currentIteration + 1);
        end
        Logger.log('forward');
    end
    
    %% run
    
    function run(this, ~, ~)
        Logger.log('run');
        this.runAlgorithm();
        this.set_currentIteration( 1 );
        plotGraph(this, this.currentIteration);
    end

    %% save
    
    function save(this, ~, ~)
        Logger.log('save');
        [fileName,pathName] = uiputfile;
        fileFullPath = [pathName fileName];
        if (0 ~= fileName)
            Logger.log(['Saving to file: ' fileFullPath]);
            this.graph.save( fileFullPath );
        end
    end

    %% open
    
    function open(this, ~, ~)
        Logger.log('open');
        fileName = uigetfile;
        if (0 ~= fileName)
            Logger.log(['Opening file: ' fileName]);
            this.graph = Graph;
            this.graph.load( fileName );
            this.run();
        end
    end

    %% print
    
    function print(this, ~, ~)
        Logger.log('print');
        directory = 'C:\technion\theses\Tex\SSL\GraphSSL_Confidence_Paper\figures\';
        algorithm = this.algorithmType;
        fileName = [directory 'illustrativeExample_' algorithm '.eps'];
        disp(['saving to file ' fileName])
        saveas(gcf, fileName);
    end

    %% onButtonDown
    
    function onButtonDown(this, ~, ~)
        Logger.log('onButtonDown');
        buttonType = get(this.figureHandle,'selectiontype');
        if MainClass.isLeftButton(buttonType)
            this.onLeftButtonDown();
%             elseif MainClass.isRightButton(buttonType)
%                 this.onRightButtonDown();
        end
    end

    %% onLeftButtonDown

    function onLeftButtonDown(this)
        Logger.log('onLeftButtonDown');
        this.leftButtonDownPosition = MainClass.getClickPosition();
    end

    %% onButtonUp

    function onButtonUp(this, ~, ~)
        Logger.log('onButtonUp');
        buttonType = get(this.figureHandle,'selectiontype');
        if MainClass.isLeftButton(buttonType)
            this.onLeftButtonUp();
        end
    end

    %% onLeftButtonUp

    function onLeftButtonUp(this)
        Logger.log('onLeftButtonUp');
        leftButtonUpPosition = MainClass.getClickPosition();

        if (isempty(this.leftButtonDownPosition) )
            Logger.log('Error: No button down position');
            return;
        end
        if (this.leftButtonDownPosition.x == leftButtonUpPosition.x && ...
            this.leftButtonDownPosition.y == leftButtonUpPosition.y)

            existing_vertex = this.findNearbyVertex ...
                ( this.leftButtonDownPosition);
            if (~isempty(existing_vertex))
                Logger.log('Error: can not add new vertex. too close to an existing vertex');
                return;
            end
            addVertex( this, leftButtonUpPosition );
        else
            v1 = this.findNearbyVertex ...
                    (   this.leftButtonDownPosition );
            v2 = this.findNearbyVertex ...
                    (   leftButtonUpPosition );

            if (~isempty(v1) && ~isempty(v2))
                % two vertices - add adge
                this.addEdge(v1, v2 );
            elseif (~isempty(v1) && isempty(v2))
                % only source vertex - move it
                this.moveVertex(v1, leftButtonUpPosition );
            end
        end
        this.leftButtonDownPosition = [];
        this.plotGraph(this.currentIteration);
    end

    %% findNearbyVertex

    function closestVertex = findNearbyVertex( this, position )
        closestVertex = [];
        radius = 0.05;
        numVertices = this.graph.numVertices();
        minDistance = 100^1000;
        for v_idx=1:numVertices
            v_pos = this.graph.vertexPosition( v_idx );
            X = 1; Y = 2;
            dx = position.x - v_pos(X);
            dy = position.y - v_pos(Y);
            distance = sqrt( dx^2 + dy^2 );
            if (distance < minDistance && ...
                distance < radius )
                minDistance = distance;
                closestVertex = v_idx;
            end
        end
    end

    %% deleteVertex

    function deleteVertex(this, ~, ~)
        Logger.log('deleteVertex');
        vertex_i = get(gco,'UserData');
        this.removeVertex( vertex_i );
        this.plotGraph(this.currentIteration);
    end

    %% deleteEdge

    function deleteEdge(this,~,~)
        Logger.log('deleteEdge');
        edgeVertices = get(gco,'UserData');
        this.removeEdge(edgeVertices(1), edgeVertices(2));
        this.plotGraph(this.currentIteration);
    end

    %% setEdgeWeight_callback

    function setEdgeWeight_callback(this,~,~)
        Logger.log('setEdgeWeight');
        edgeVertices = get(gco,'UserData');
        prompt={'Enter weight:'};
        name='Input edge weight';
        numlines=1;
        defaultanswer={'1'};
        weight=inputdlg(prompt,name,numlines,defaultanswer);
        this.setEdgeWeight(edgeVertices(1), edgeVertices(2), str2double(weight{1}));
        this.plotGraph(this.currentIteration);            
    end
    
    %% setVertexPositive

    function setVertexPositive(this, ~, ~)
        Logger.log('setVertexPositive');
        this.updateVertex('positive');
    end

    %% setVertexNegative
    
    function setVertexNegative(this, ~, ~)
        Logger.log('setVertexNegative');
        this.updateVertex('negative');
    end

    %% setVertexUnlabled
    
    function setVertexUnlabled(this, ~, ~)
        Logger.log('setVertexUnlabled');
        this.updateVertex('none');
    end
    
    %% setVertexOrder
    
    function setVertexOrder(this, ~, ~)
        Logger.log('setVertexOrder');
        order = this.askUserForNumericInput('Enter vertex order:', 'Input Vertex Order');
        if isempty(order)
            Logger.log('Cancel');
            return;
        end
        vertexID = get(gco,'UserData');
        Logger.log(['Vertex = ' num2str(vertexID) '. order = ' num2str(order)]);
        this.graph.set_vertexOrderIndex(vertexID, order);
    end
    
    %% askUserForInput
    
    function R = askUserForNumericInput( ~, prompt, name )
        numlines=1;
        defaultanswer={'1'};
        R = inputdlg(prompt,name,numlines,defaultanswer);
        if ~isempty(R)
            R = str2double(R{1});
        end
    end

    %% updateNumIterations
    
    function updateNumIterations(this, ~, ~)
        Logger.log('updateNumIterations');
        newValue = get(gco,'string');
        newNumericValue = str2double(newValue);
        if ceil(newNumericValue) == floor(newNumericValue)
            this.numIterations = newNumericValue;
        else
            Logger.log(['Error: new value ' newValue ' is not an integer']);
        end
        this.run();
    end

    %% updateCurrentIteration
    
    function updateCurrentIteration(this,~,~)
        Logger.log('updateCurrentIteration');
        newValue = get(gco,'string');
        newNumericValue = str2double(newValue);
        if ceil(newNumericValue) == floor(newNumericValue)
            if newNumericValue <= this.numIterations
                this.currentIteration = newNumericValue;
            else
                Logger.log(['Error: new value ' newValue ' is larger then '...
                      'maximal value ' num2str( this.numIterations )]);
            end
        else
            Logger.log(['Error: new value ' newValue ' is not an integer']);
        end
        this.plotGraph(this.currentIteration);
    end

    %% updateAlpha
    
    function updateAlpha(this, ~, ~)
        this.updateParamAndRun('alpha');
    end

    %% updateBeta
    
    function updateBeta(this, ~, ~)
        this.updateParamAndRun('beta');
    end

    %% updateLabeledConfidence
    
    function updateLabeledConfidence(this, ~, ~)
        this.updateParamAndRun('labeledConfidence');
    end
    
    %% updateZeta
    
    function updateZeta(this,~,~)
        this.updateParamAndRun('zeta');
    end
    
    %% updateStayInStateProbability
    
    function updateStayInStateProbability(this,~,~)
        this.updateParamAndRun('m_stayInStateProbability');
    end
    
    %% updateParamAndRun
    
    function updateParamAndRun(this, paramName)
        Logger.log(['Updating ' paramName]);
        newValue = get(gco,'string');
        Logger.log(['New value is ' newValue]);
        this.(paramName) = str2double(newValue);
        this.run();
    end

    %% updateMu2
    
    function updateMu2(this, ~, ~)
        this.updateParamAndRun('mu2');
    end

    %% updateMu3
    
    function updateMu3(this, ~, ~)
        this.updateParamAndRun('mu3');
    end

    %% updateAlgorithm
    
    function updateAlgorithm(this, hObj, ~)
        Logger.log('updateAlgorithm');
        selectedIndex = get(hObj,'Value');
        values        = get(hObj,'String');
        this.algorithmType = values(selectedIndex,:);
        this.algorithmType( this.algorithmType == ' ') = [];
        this.run();
    end

%********************** Private helpers ***************************

    %% doPlot

    function doPlot(this, E, iteration_i)

        fontSize = 10;
        %fontSize = 18;
        markerSize = 60;

        numVertices = this.graph.numVertices();

        md=inf; % the minimal distance between vertexes
        for k1=1:numVertices-1,
            for k2=k1+1:numVertices,
                k1_pos = this.graph.vertexPosition(k1);
                k2_pos = this.graph.vertexPosition(k2);
                md=min(md,sum((k1_pos-k2_pos).^2)^0.5);
            end
        end
        if md<eps, % identical vertexes
          error('The array V has identical rows!')
        end

        hold on
        axis equal

        numRegularEdges = size(E,1);
        isStructured = zeros(numRegularEdges,1);
        structuredEdges = this.graph.structuredEdges();
        E = [E; structuredEdges];
        isStructured = [isStructured;ones(size(structuredEdges,1),1)];
        
        % edges (arrows)
        numEdges = size(E,1);
        for currentEdge_i=1:numEdges,
            edgeVertices = E(currentEdge_i,:);

            start_vertex_idx = edgeVertices(1);
            end_vertex_idx   = edgeVertices(2);

            edgeStartPosition = this.graph.vertexPosition( start_vertex_idx );
            edgeEndPosition   = this.graph.vertexPosition( end_vertex_idx );

            edge = [ edgeStartPosition;
                     edgeEndPosition];
            edge_weight = this.graph.getEdgeWeight( start_vertex_idx, end_vertex_idx ); 

            X = 1; Y = 2;
            isStructuredEdge = isStructured(currentEdge_i);
            if isStructuredEdge
                color = '-r';
            else
                color = '-k';
            end
            plot(edge(:,X),edge(:,Y),color,      ...
                    'UserData'     , edgeVertices,   ... 
                    'ButtonDownFcn', ...
                    {@(src, event)onButtonDown(this, src, event)});
            if this.m_showEdgeWeights && ~isStructuredEdge
                edgeText = num2str(edge_weight);
                edge_text_pos = mean(edge, 1) + [0.01 0.01];
                text( edge_text_pos (X), edge_text_pos (Y), edgeText, ...
                     'DisplayName', ...
                     ['text_e_' num2str(start_vertex_idx) num2str(end_vertex_idx)] );
            end
        end

        % we paint the graph

        verticesPosition = this.graph.allVerticesPositions();

        X = 1;
        Y = 2;
        color = this.algorithm_result.allColors( iteration_i );

        max_color = max (abs(color));
        color = color / max_color;

        scatter( verticesPosition(:,X), ...
                 verticesPosition(:,Y), ...
            ones(numVertices, 1) * markerSize, color, ...
            'filled', ...
            'ButtonDownFcn', {@(src, event)onButtonDown(this, src, event)}, ...
            'MarkerEdgeColor', 'k');
        %limit = max(abs(color));
        caxis([-1 1]);
        caxis manual;
        colormap(gray);
        colorbar;

        % write vertex legend
        if this.m_showLegend
            text(0,0,this.algorithm_result.legend(),'Units','pixels');
        end

        for vertex_i=1:numVertices,

           %v_pos = this.graph.vertexPosition( vertex_i );
           if this.graph.isShowText( vertex_i)
               vertexNumericText = this.algorithm_result.asText ...
                                ( vertex_i, iteration_i );
               X = 1; Y = 2;
               vertexTextPosition = this.graph.vertexTextPosition( vertex_i );

               %disp('vertexTextPosition');
               %disp(vertexTextPosition);
               text_pos.x = vertexTextPosition (X);
               text_pos.y = vertexTextPosition( Y );
               if this.graph.vertexHasName(vertex_i)
                   vertexNameText = ['\textbf{' this.graph.vertexName(vertex_i) '}       '];
               else
                   vertexNameText = [];
               end

               vertexText = vertexNameText;
               if this.m_showNumericResults
                   vertexText = [vertexText vertexNumericText]; %#ok<AGROW>
               end

               text( text_pos.x, text_pos.y, vertexText, ...
                     'DisplayName', ['text_v_' num2str(vertex_i)], ...
                     'UserData'   , vertex_i, ...
                     'Interpreter', 'latex',...
                     'FontSize', fontSize);

               if this.graph.isShowArrow(vertex_i)
                    % currently not working
                    vertexPosition = this.graph.vertexPosition(vertex_i);

                    vertexPosition = this.convertToNormalizedFigureUnits(vertexPosition);
                    vertexTextPosition = this.convertToNormalizedFigureUnits(vertexTextPosition);

                    xCord = [vertexTextPosition(X) vertexPosition(Y)];
                    ycord = [vertexTextPosition(X) vertexPosition(Y)];
 %Create the textarrow object: 
                    %annotation('textarrow',xCord,ycord,...
                    %    'String','C','FontSize',14);
                end
           end
        end

        hold off
        axis off
    end

    %% convertToNormalizedFigureUnits
    
    function R = convertToNormalizedFigureUnits(~,plotPoint)
        axPos = get(gca,'Position'); %# gca gets the handle to the current axes
        xMinMax = xlim;
        yMinMax = ylim;
        xAnnotation = axPos(1) + ((plotPoint(1) - xMinMax(1))/(xMinMax(2)-xMinMax(1))) * axPos(3);
        yAnnotation = axPos(2) + ((plotPoint(2) - yMinMax(1))/(yMinMax(2)-yMinMax(1))) * axPos(4);
        R = [xAnnotation yAnnotation];
    end

    %% addVertex
    
    function addVertex( this, position )
        old_num_vertices = this.graph.numVertices();
        Logger.log(['Old num vertices: ' num2str(old_num_vertices)]);
        Logger.log(['Adding vertex:(' num2str(position.x) ',' num2str(position.y) ')']);

        this.graph.addVertex( position );
        this.algorithm_result.add_vertex();

        new_num_vertices = this.graph.numVertices();
        Logger.log(['New num vertices: ' num2str(new_num_vertices)]);
    end
    
    %% removeVertex

    function removeVertex(this, vertex_i )
        Logger.log('removeVertex');
        if (~isempty(vertex_i))
            this.graph.removeVertex(vertex_i);
            this.algorithm_result.remove_vertex(vertex_i);
        else
            Logger.log('No nearby vertex');
        end
    end

    %% moveVertex
    
    function moveVertex(this, v, newPosition)
        this.graph.moveVertex( v, newPosition );
    end

    %% removeEdge
    
    function removeEdge(this, v1, v2)
        this.graph.removeEdge( v1, v2 );
    end

    %% setEdgeWeight
    
    function setEdgeWeight(this, v1, v2, weight)
        this.graph.setEdgeWeight(v1,v2,weight);
    end

    %% addEdge
    
    function addEdge(this, v1, v2 )
        this.graph.addEdge( v1, v2 );
    end

    %% updateVertex
    
    function updateVertex(this, updateType)
        vertex_i = get(gco,'UserData');
        this.updateVertexIndex(updateType, vertex_i);
    end

    %% updateVertexIndex
    
    function updateVertexIndex(this, updateType, vertex_i)
        if (isempty(vertex_i))
            Logger.log('Error: no vertex index');
            return;
        end

        switch updateType
            case 'positive'
                this.graph.setVertexLabel...
                    ( vertex_i, this.graph.positiveLabel() );
            case 'negative'
                this.graph.setVertexLabel...
                    ( vertex_i, this.graph.negativeLabel() );
            case 'none'
                this.graph.clearLabels(vertex_i);
            otherwise
                Logger.log(['Error: unknown update type: ''' updateType ''''] );
        end

        this.run();
    end

    %% createFigureToolbar
    
    function fig = createFigureToolbar(this)

        fig  =  figure( ...
           'ToolBar','none', ...
           'ButtonDownFcn',     @(src, event)onButtonDown(this, src, event), ...
           'WindowButtonUpFcn', @(src, event)onButtonUp  (this, src, event));
        toolbar = uitoolbar(fig);

        cdataRedo = MainClass.loadIcon( 'greenarrowicon.gif' );
        cdataUndo = cdataRedo(:,[16:-1:1],:);

        % Add the icon (and its mirror image = undo) to the latest toolbar
        uipushtool( toolbar, ...
          'cdata'           ,cdataUndo, ...
          'tooltip'         ,'back', ...
          'ClickedCallback' , {@(src, event)back(this, src, event)});

        uipushtool( toolbar, ...
          'cdata'           ,cdataRedo, ...
          'tooltip'         ,'forward', ...
          'ClickedCallback' , {@(src, event)forward(this, src, event)});

        MainClass.addIconToUI(toolbar, 'tool_rotate_3d.gif', ...
            'run', {@(src, event)run(this, src, event)});
        MainClass.addIconToUI(toolbar, 'file_save.png', ...
            'save', {@(src, event)save(this, src, event)});
        MainClass.addIconToUI(toolbar, 'file_open.png', ...
            'open', {@(src, event)open(this, src, event)});
        MainClass.addIconToUI(toolbar, 'tool_plot_linked.png', ...
            'print', {@(src, event)print(this, src, event)});
    end

    %% createPlotInfo
    
    function createPlotInfo(this)
        this.plotInfo.Edges = MainClass.createEdges(this.graph.weights());
        this.currentIteration = 1;
    end

    %% addVerticesContextMenu 
    
    function addVerticesContextMenu(this)
        Logger.log('Adding context menu to vertices');
        % Create axes and save handle
        hax = gca;
        % Define a context menu; it is not attached to anything
        hcmenu = uicontextmenu;
        % Define the context menu items and install their callbacks
        uimenu(hcmenu, 'Label', 'Delete', ...
                       'Callback', @(src, event)deleteVertex(this, src, event));
        uimenu(hcmenu, 'Label', 'Positive',...
                       'Callback', @(src, event)setVertexPositive(this, src, event));
        uimenu(hcmenu, 'Label', 'Negative',  ...
                       'Callback', @(src, event)setVertexNegative(this, src, event));
        uimenu(hcmenu, 'Label', 'Unlabeled', ...
                        'Callback', @(src, event)setVertexUnlabled(this, src, event));
        uimenu(hcmenu, 'Label', 'Set Order', ...
                        'Callback', @(src, event)setVertexOrder(this, src, event));

        % Locate vertices object
%             points = findall(hax,'DisplayName','vertices');
        objectWithContextMenu = findall(hax,'Type','text');

%             Logger.log(length(objectWithContextMenu));
        % Attach the context menu to each text element
        for object_i = 1:length(objectWithContextMenu)
            set(objectWithContextMenu(object_i),...
                'UIContextMenu',hcmenu)
        end
    end

    %% addEdgesContextMenu

    function addEdgesContextMenu(this)
        Logger.log('Adding context menu to edges');
        % Create axes and save handle
        hax = gca;
        % Define a context menu; it is not attached to anything
        hcmenu = uicontextmenu;
        % Define the context menu items and install their callbacks
        uimenu(hcmenu, 'Label', 'Delete', ...
                       'Callback', @(src, event)deleteEdge(this, src, event));
        uimenu(hcmenu, 'Label', 'Set Weight',...
                       'Callback', @(src, event)setEdgeWeight_callback(this, src, event));
        % Locate the objects we want to add the menu to
        objectWithContextMenu = findall(hax,'Type','line');

        % Attach the context menu to each edge element
        for object_i = 1:length(objectWithContextMenu)
            set(objectWithContextMenu(object_i),...
                'UIContextMenu',hcmenu)
        end
    end

    %% addParamsUI

    function addParamsUI(this)
        INITIAL_LEFT_POSITION = 30;
        INITIAL_BOTTOM_POSITION = 0;
        controlPos.left = INITIAL_LEFT_POSITION;
        controlPos.bottom = INITIAL_BOTTOM_POSITION;
        controlPos.width = 100;
        controlPos.height = 20;
        margin = 5;

        this.iterationsUI = ...
        MainClass.addParam( controlPos, 'total iterations', this.numIterations, ...
                        @(src, event)updateNumIterations(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;

        MainClass.addParam( controlPos, 'alpha', this.alpha, ...
                        @(src, event)updateAlpha(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;

        MainClass.addParam( controlPos, 'beta', this.beta, ...
                        @(src, event)updateBeta(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;

        MainClass.addParam( controlPos, 'labeled confidence', ... 
                        this.labeledConfidence, ...
              @(src, event)updateLabeledConfidence(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;

        MainClass.addParam( controlPos, 'mu2', this.mu2, ...
                        @(src, event)updateMu2(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;

        MainClass.addParam( controlPos, 'mu3', this.mu3, ...
                        @(src, event)updateMu3(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;

        algorithmOptions = [CSSL.name()    '|' CSSLMC.name() '|' ...
                            CSSLMCF.name() '|' ...
                            LP.name()      '|' MAD.name() '|' ...
                            AM.name()] ;
        MainClass.addComboParam( controlPos, 'algorithm', ... 
                        algorithmOptions, ...
              @(src, event)updateAlgorithm(this, src, event) );
          controlPos.left = controlPos.left + controlPos.width + margin;

        this.currentIterationUI = ...
        MainClass.addParam( controlPos, 'iteration', ... 
                        this.labeledConfidence, ...
              @(src, event)updateCurrentIteration(this, src, event) );
        
        controlPos.left = INITIAL_LEFT_POSITION;
        controlPos.bottom = INITIAL_BOTTOM_POSITION + 2*(controlPos.height + margin);
        MainClass.addParam( controlPos, 'zeta', this.zeta, ...
                        @(src, event)updateZeta(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;
        
        MainClass.addParam( controlPos, 'Stay Prob', this.m_stayInStateProbability, ...
                        @(src, event)updateStayInStateProbability(this, src, event) );
        controlPos.left = controlPos.left + controlPos.width + margin;

    end

    %% runCSSL

    function runCSSL(this)

        cssl = CSSL;

        cssl.m_W = this.graph.weights();
        cssl.m_num_iterations = this.numIterations;
        cssl.m_alpha = this.alpha;
        cssl.m_beta = this.beta;
        cssl.m_labeledConfidence = this.labeledConfidence;

        positiveInitialValue = +1;
        negativeInitialValue = -1;
        this.algorithm_result = CSSL_Result;
        R = cssl.runBinary ...
                      ( this.graph.labeled_positive(), ...
                        this.graph.labeled_negative(), ...
                        positiveInitialValue,...
                        negativeInitialValue );
        this.algorithm_result.set_results( R );
    end

    %% runCSSLMC

    function runCSSLMC(this)

        algorithm = CSSLMC;

        algorithm.m_W = this.graph.weights();
        algorithm.m_num_iterations = this.numIterations;
        algorithm.m_alpha = this.alpha;
        algorithm.m_beta = this.beta;
        algorithm.m_labeledConfidence = this.labeledConfidence;
        algorithm.m_zeta = this.zeta;
        algorithm.m_isUsingL2Regularization = 0;
        algorithm.m_isUsingSecondOrder = 1;
        algorithm.setLabeledSet(this.graph.labeled());
        algorithm.m_isCalcObjective = this.m_isCalcObjective;
        algorithm.m_save_all_iterations = 1;

        Y = MainClass.createLabeledY(this.graph);
        algorithm.m_priorY = Y;
        
        a = this.m_stayInStateProbability;
        transitionMatrix = [ a  1-a;
                            1-a  a  ];
        algorithm.setTransitionMatrix( transitionMatrix );
        algorithm.setStructuredEdges( this.graph.structuredEdges() );
        algorithm.m_isUsingStructured = 1;
        
        algorithm.m_useClassPriorNormalization = 0;
        
        this.algorithm_result = CSSLMC_Result;
        R = algorithm.run ();
        saveAllIterations = 1;
        this.algorithm_result.set_results( R, saveAllIterations );
        this.set_numIterations( this.algorithm_result.numIterations() );
    end

    %% runCSSLMCF

    function runCSSLMCF(this)

        algorithm = CSSLMCF;

        algorithm.m_W = this.graph.weights();
        algorithm.m_num_iterations = this.numIterations;
        algorithm.m_alpha = this.alpha;
        algorithm.m_beta = this.beta;
        algorithm.m_labeledConfidence = this.labeledConfidence;
        algorithm.m_isUsingL2Regularization = 0;
        algorithm.m_isUsingSecondOrder = 1;
        algorithm.m_save_all_iterations = 1;
        algorithm.setLabeledSet(this.graph.labeled());

        Y = MainClass.createLabeledY(this.graph);
        algorithm.m_priorY = Y;
        
        algorithm.m_useClassPriorNormalization = 0;

        this.algorithm_result = CSSLMCF_Result;
        R = algorithm.run ();
        saveAllIterations = 1;
        this.algorithm_result.set_results( R, saveAllIterations );
        this.set_numIterations( this.algorithm_result.numIterations() );
    end

    %% runLP

    function runLP(this)
        lp = LP;
        this.algorithm_result = LP_Results;
        R = lp.run( this.graph.weights(),...
                    this.graph.labeled_positive(),...
                    this.graph.labeled_negative() );
        this.algorithm_result.set_results( R );
    end

    %% runMAD

    function runMAD(this)
        algorithm = MAD;

        algorithm.m_W = this.graph.weights();
        algorithm.m_mu1 = 1;
        algorithm.m_mu2 = this.mu2;
        algorithm.m_mu3 = this.mu3;
        algorithm.m_useGraphHeuristics = 1;
        algorithm.m_num_iterations = this.numIterations; 
        algorithm.m_save_all_iterations = 1;
        algorithm.setLabeledSet(this.graph.labeled());

        Y = MainClass.createLabeledY(this.graph);
        algorithm.m_priorY = Y;
        
        algorithm.m_useClassPriorNormalization = 0;

        this.algorithm_result = MAD_Results;
        R = algorithm.run();
        saveAllIterations = 1;
        this.algorithm_result.set_results( R, saveAllIterations );
        this.set_numIterations( this.algorithm_result.numIterations() );
    end

    %% runAM

    function runAM(this)
        algorithm = AM;

        algorithm.m_v = 0.001;
        algorithm.m_mu = 0.01;
        algorithm.m_alpha = 2;
        algorithm.m_num_iterations = this.numIterations; 
        algorithm.m_W  = this.graph.weights();
        algorithm.m_save_all_iterations = 1;
        algorithm.setLabeledSet(this.graph.labeled());

        Y = MainClass.createLabeledY(this.graph);
        algorithm.m_priorY = Y;

        this.algorithm_result = AM_Result;
        R = algorithm.run();
        saveAllIterations = 1;
        this.algorithm_result.set_results( R, saveAllIterations );
        this.set_numIterations( this.algorithm_result.numIterations() );
    end        

end % private methods

%********************** STATIC ***************************

methods(Static)

    %% createLabeledY
    
    function labeledY = createLabeledY( graph )
        numVertices = graph.numVertices();
        numLabels   = graph.numLabels();
        labeledY = zeros( numVertices, numLabels);
        NEGATIVE = 1; POSITIVE = 2;
        labeledY( graph.labeled_negative(), NEGATIVE ) = 1;
        labeledY( graph.labeled_positive(), POSITIVE ) = 1;
    end

    %% getClickPosition
    
    function curPos = getClickPosition()
        coordinates = get(gca,'CurrentPoint');
        %Logger.log(coordinates));
        curPos.x = coordinates(1,1);
        curPos.y = coordinates(1,2);
    end

    %% isLeftButton
    
    function result = isLeftButton(button)
        result =  strcmpi(button,'normal');
    end

    %% isRightButton
    
    function result = isRightButton(button)
        result =  strcmpi(button,'alt');
    end

    %% addIconToUI
    
    function addIconToUI(toolbar, iconName, tooltip, eventHandler)
        cdata = MainClass.loadIcon( iconName );

        uipushtool( toolbar,            ...
                    'cdata',            cdata, ...
                    'tooltip',          tooltip, ...
                    'ClickedCallback',  eventHandler);
    end

    %% loadIcon
    
    function iconData = loadIcon( iconName )
        % Load the icon
        icon = fullfile(matlabroot,['/toolbox/matlab/icons/' iconName]);
        [cdata,map] = imread(icon);

        if (~isempty(map))
            % Convert white pixels into a transparent background
            map(find(map(:,1)+map(:,2)+map(:,3)==3)) = NaN;

            % Convert into 3D RGB-space
            iconData = ind2rgb(cdata,map);
        else
            iconData = cdata;
            iconData = iconData / (2^16);
        end
    end

    %% addParam

    function h = addParam( controlPos, label, value, callback)
        margin = 5;
        labelPos = controlPos;
        labelPos.bottom = labelPos.bottom + controlPos.height + margin;
        uicontrol('style','text',...
             'units','pix',...
             'position',[labelPos.left  labelPos.bottom ...
                         labelPos.width labelPos.height],...
             'string',label,...
             'fontsize',8);

        h = uicontrol('style','edit',...
             'units','pix',...
             'position',[controlPos.left  controlPos.bottom ...
                         controlPos.width controlPos.height],...
             'string',num2str(value),...
             'fontsize',11,...
             'callback',callback);
    end

    %% addComboParam
    
    function addComboParam( controlPos, label, values, callback)
        margin = 5;
        labelPos = controlPos;
        labelPos.bottom = labelPos.bottom + controlPos.height + margin;
        uicontrol('style','text',...
             'units','pix',...
             'position',[labelPos.left  labelPos.bottom ...
                         labelPos.width labelPos.height],...
             'string',label,...
             'fontsize',8);

        uicontrol('style','popupmenu',...
             'units','pix',...
             'position',[controlPos.left  controlPos.bottom ...
                         controlPos.width controlPos.height],...
             'string',values,...
             'fontsize',11,...
             'callback',callback);
    end
    
    %% createEdges

    function E = createEdges(W)

        num_vertices = size(W,1);
        num_edges = length( W(W~=0) ) / 2;

        E = zeros(num_edges,2);

        vertex_i = 1;
        for row=1:num_vertices
            for col=1:num_vertices
                if ( 0 ~= W(row,col) && row < col  )
                    E(vertex_i,:) = [row col];
                    vertex_i = vertex_i + 1;
                end
            end
        end

    end
end % Static methods

end

