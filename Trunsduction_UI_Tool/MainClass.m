classdef MainClass < handle
    %CLASS1 Summary of this class goes here
    %   Detailed explanation goes here
    % http://stackoverflow.com/questions/106086/in-matlab-can-a-class-method-act-as-a-uicontrol-callback-without-being-public
    
    properties (Access=public)
        %graph;
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
        leftButtonDownPosition;
        algorithmType;
%         rightButtonDownPosition;
    end

%********************** PUBLIC ***************************

    methods (Access = public)
        function this = MainClass() % Constructor
            this.numIterations = 100;
            this.beta = 1;
            this.alpha = 1;
            this.labeledConfidence = 0.1;
            this.algorithmType = CSSL.name();
        end
        
        function set_graph( this, graphStruct )
            this.graph = Graph;
            this.graph.loadFromStruct(graphStruct);
        end
        
        function set_numIterations(this, value)
            this.numIterations = value;
            set(this.iterationsUI, 'String', num2str( value ) );
        end
        
        function set_currentIteration(this, value)
            this.currentIteration = value;
            set(this.currentIterationUI, 'String', num2str( value ) );
        end
        
        function runAlgorithm(this)   
            disp( ['algorithm type = ' this.algorithmType ] );
            if (strcmp( this.algorithmType,LP.name() ) == 1)
                this.runLP();
            elseif (strcmp( this.algorithmType,CSSL.name() ) == 1)
                this.runCSSL();
            elseif (strcmp( this.algorithmType,MAD.name() ) == 1)
                this.runMAD();
            else
                disp('Error: unknown algorithm');
            end
        end
        
        function plotGraph(this, iter_i)

            disp(['plotGraph: ' num2str(iter_i)]);
            if (isempty( this.figureHandle ) )
                disp('Creating figure...');
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
        
        function back(this, ~, ~)
            if (this.currentIteration > 1)
                plotGraph(this, this.currentIteration - 1);
            end
            disp('back');
        end
        
        function forward(this, ~, ~)
            if (this.currentIteration < this.numIterations)
                plotGraph(this, this.currentIteration + 1);
            end
            disp('forward');
        end
        
        function run(this, ~, ~)
            disp('run');
            this.runAlgorithm();
            this.set_currentIteration( 1 );
            plotGraph(this, this.currentIteration);
        end
        
        function save(this, ~, ~)
            disp('save');
            fileName = uiputfile;
            if (0 ~= fileName)
                disp(['Saving to file: ' fileName]);
                this.graph.save( fileName );
                %graph = this.graph;
                %save(fileName, 'graph' );
            end
        end
        
        function open(this, ~, ~)
            disp('open');
            fileName = uigetfile;
            if (0 ~= fileName)
                disp(['Opening file: ' fileName]);
                this.graph = Graph;
                this.graph.load( fileName );
                this.run();
            end
        end

        function onButtonDown(this, ~, ~)
            disp('onButtonDown');
            buttonType = get(this.figureHandle,'selectiontype');
            if MainClass.isLeftButton(buttonType)
                this.onLeftButtonDown();
%             elseif MainClass.isRightButton(buttonType)
%                 this.onRightButtonDown();
            end
        end
        
        function onLeftButtonDown(this)
            disp('onLeftButtonDown');
            this.leftButtonDownPosition = MainClass.getClickPosition();
        end

        function onButtonUp(this, ~, ~)
            disp('onButtonUp');
            buttonType = get(this.figureHandle,'selectiontype');
            if MainClass.isLeftButton(buttonType)
                this.onLeftButtonUp();
            end
        end
        
        function onLeftButtonUp(this)
            disp('onLeftButtonUp');
            leftButtonUpPosition = MainClass.getClickPosition();
            
            if (isempty(this.leftButtonDownPosition) )
                disp('Error: No button down position');
                return;
            end
            if (this.leftButtonDownPosition.x == leftButtonUpPosition.x && ...
                this.leftButtonDownPosition.y == leftButtonUpPosition.y)
            
                existing_vertex = this.findNearbyVertex ...
                    ( this.leftButtonDownPosition);
                if (~isempty(existing_vertex))
                    disp('Error: can not add new vertex. too close to an existing vertex');
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
        
        function deleteVertex(this, ~, ~)
            disp('deleteVertex');
            vertex_i = get(gco,'UserData');
            this.removeVertex( vertex_i );
            this.plotGraph(this.currentIteration);
        end
        
        function deleteEdge(this,~,~)
            disp('deleteEdge');
            edgeVertices = get(gco,'UserData');
            this.removeEdge(edgeVertices(1), edgeVertices(2));
            this.plotGraph(this.currentIteration);
        end
        
        function setVertexPositive(this, ~, ~)
            disp('setVertexPositive');
            this.updateVertex('positive');
        end
        
        function setVertexNegative(this, ~, ~)
            disp('setVertexNegative');
            this.updateVertex('negative');
        end
        
        function setVertexUnlabled(this, ~, ~)
            disp('setVertexUnlabled');
%             vertex_i = get(gco,'UserData');
            this.updateVertex('none');
        end
        
        function updateNumIterations(this, ~, ~)
            disp('updateNumIterations');
            newValue = get(gco,'string');
            newNumericValue = str2double(newValue);
            if ceil(newNumericValue) == floor(newNumericValue)
                this.numIterations = newNumericValue;
            else
                disp(['Error: new value ' newValue ' is not an integer']);
            end
            this.run();
        end
        
        function updateCurrentIteration(this,~,~)
            disp('updateCurrentIteration');
            newValue = get(gco,'string');
            newNumericValue = str2double(newValue);
            if ceil(newNumericValue) == floor(newNumericValue)
                if newNumericValue <= this.numIterations
                    this.currentIteration = newNumericValue;
                else
                    disp(['Error: new value ' newValue ' is larger then '...
                          'maximal value ' num2str( this.numIterations )]);
                end
            else
                disp(['Error: new value ' newValue ' is not an integer']);
            end
            this.plotGraph(this.currentIteration);
        end
        
        function updateAlpha(this, ~, ~)
            disp('updateAlpha');
            newValue = get(gco,'string');
            this.alpha = str2double(newValue);
            this.run();
        end

        function updateBeta(this, ~, ~)
            disp('updateBeta');
            newValue = get(gco,'string');
            this.beta = str2double(newValue);
            this.run();
        end

        function updateLabeledConfidence(this, ~, ~)
            disp('updateLabeledConfidence');
            newValue = get(gco,'string');
            this.labeledConfidence = str2double(newValue);
            this.run();
        end
        
        function updateAlgorithm(this, hObj, ~)
            disp('updateAlgorithm');
            selectedIndex = get(hObj,'Value');
            values        = get(hObj,'String');
            this.algorithmType = values(selectedIndex,:);
            this.algorithmType( this.algorithmType == ' ') = [];
            this.run();
        end

%********************** Private helpers ***************************

        function doPlot(this, E, iteration_i)
         
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
            else
              % MATAN 7.11.11 removed
              % don't normalize because we added interactive graph
              % creation
              %V(:,1:2)=V(:,1:2)/md; % normalization 
            end
            
            hold on
            axis equal

            % edges (arrows)
            numEdges = size(E,1);
            for currentEdge_i=1:numEdges,
                edgeVertices = E(currentEdge_i,:);
                
                edge_start_idx = edgeVertices(1);
                edge_end_idx   = edgeVertices(2);
                
                edge = [    this.graph.vertexPosition( edge_start_idx );
                            this.graph.vertexPosition( edge_end_idx ) ];
                        
                X = 1; Y = 2;
                plot(edge(:,X),edge(:,Y),'k-',      ...
                        'UserData'     , edgeVertices,   ... 
                        'ButtonDownFcn', ...
                        {@(src, event)onButtonDown(this, src, event)});
              
%                 if ~isempty(ekind), % labels of edges (arrows)
%                     if we==3,
%                         s=sprintf(ekind,E2(currentEdge_i+k2-1,5));
%                     else
%                         s=sprintf(ekind,E2(currentEdge_i+k2-1,2));
%                     end
%                     text(MyXg(length(MyXg)/2),MyYg(length(MyYg)/2),s);
%                 end
            end
        
            % we paint the graph
            
            verticesPosition = this.graph.allVerticesPositions();
            
            X = 1;
            Y = 2;
            color = this.algorithm_result.allColors( iteration_i );
            scatter( verticesPosition(:,X), ...
                     verticesPosition(:,Y), ... 
                ones(numVertices, 1) * 40, color, ...
                'filled', ...
                'ButtonDownFcn', {@(src, event)onButtonDown(this, src, event)});
            colorbar;
            
            % write vertex legend
            text(0,0,this.algorithm_result.legend(),'Units','pixels');

            for vertex_i=1:numVertices,
               vertexText = this.algorithm_result.asText ...
                                    ( vertex_i, iteration_i );
               v_pos = this.graph.vertexPosition( vertex_i );
               X = 1; Y = 2;
               text_pos.x = v_pos(X)+0.05;
               text_pos.y = v_pos(Y)-0.07;
               text( text_pos.x, text_pos.y, vertexText, ...
                     'DisplayName', ['text_v_' num2str(vertex_i)], ...
                     'UserData'   , vertex_i );
            end
            
            hold off
            axis off
        end

        function addVertex( this, position )
            old_num_vertices = this.graph.numVertices();
            disp(['Old num vertices: ' num2str(old_num_vertices)]);
            disp(['Adding vertex:(' num2str(position.x) ',' num2str(position.y) ')']);

            this.graph.addVertex( position );
            this.algorithm_result.add_vertex();
            
            new_num_vertices = this.graph.numVertices();
            disp(['New num vertices: ' num2str(new_num_vertices)]);
        end
        
        function removeVertex(this, vertex_i )
            disp('removeVertex');
            if (~isempty(vertex_i))
                this.graph.removeVertex(vertex_i);
                this.algorithm_result.remove_vertex(vertex_i);
            else
                disp('No nearby vertex');
            end
        end
        
        function moveVertex(this, v, newPosition)
            this.graph.moveVertex( v, newPosition );
        end
        
        function removeEdge(this, v1, v2)
            this.graph.removeEdge( v1, v2 );
        end

        function addEdge(this, v1, v2 )
            this.graph.addEdge( v1, v2 );
        end
        
        function updateVertex(this, updateType)
            vertex_i = get(gco,'UserData');
            this.updateVertexIndex(updateType, vertex_i);
        end
        
        function updateVertexIndex(this, updateType, vertex_i)
            if (isempty(vertex_i))
                disp('Error: no vertex index');
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
                    disp(['Error: unknown update type: ''' updateType ''''] );
            end
            
            this.run();
        end
        
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
        end
        
        function createPlotInfo(this)
            this.plotInfo.Edges = MainClass.createEdges(this.graph.weights());
            this.currentIteration = 1;
        end
        
        function addVerticesContextMenu(this)
            disp('Adding context menu to vertices');
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
            % Locate vertices object
%             points = findall(hax,'DisplayName','vertices');
            objectWithContextMenu = findall(hax,'Type','text');
            
%             disp(length(objectWithContextMenu));
            % Attach the context menu to each text element
            for object_i = 1:length(objectWithContextMenu)
                set(objectWithContextMenu(object_i),...
                    'UIContextMenu',hcmenu)
            end
        end
        
        function addEdgesContextMenu(this)
            disp('Adding context menu to edges');
            % Create axes and save handle
            hax = gca;
            % Define a context menu; it is not attached to anything
            hcmenu = uicontextmenu;
            % Define the context menu items and install their callbacks
            uimenu(hcmenu, 'Label', 'Delete', ...
                           'Callback', @(src, event)deleteEdge(this, src, event));
            % Locate the objects we want to add the menu to
            objectWithContextMenu = findall(hax,'Type','line');
            
            % Attach the context menu to each text element
            for object_i = 1:length(objectWithContextMenu)
                set(objectWithContextMenu(object_i),...
                    'UIContextMenu',hcmenu)
            end
        end
        
        function addParamsUI(this)
            controlPos.left = 30;
            controlPos.bottom = 0;
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
            
            MainClass.addComboParam( controlPos, 'algorithm', ... 
                            [CSSL.name() '|' LP.name() '|' MAD.name()], ...
                  @(src, event)updateAlgorithm(this, src, event) );
              controlPos.left = controlPos.left + controlPos.width + margin;

            this.currentIterationUI = ...
            MainClass.addParam( controlPos, 'iteration', ... 
                            this.labeledConfidence, ...
                  @(src, event)updateCurrentIteration(this, src, event) );
        end
        
        function runCSSL(this)
            
            cssl = CSSL;
            
            cssl.m_W = this.graph.weights();
            cssl.m_num_iterations = this.numIterations;
            cssl.m_alpha = this.alpha;
            cssl.m_beta = this.beta;
            
            positiveInitialValue = +1;
            negativeInitialValue = -1;
            this.algorithm_result = CSSL_Result;
            R = cssl.runBinary ...
                          ( this.graph.labeled_positive(), ...
                            this.graph.labeled_negative(), ...
                            positiveInitialValue,...
                            negativeInitialValue,...
                            this.labeledConfidence );
            this.algorithm_result.set_results( R );
        end
        
        function runLP(this)
            lp = LP;
            this.algorithm_result = LP_Results;
            R = lp.run( this.graph.weights(),...
                        this.graph.labeled_positive(),...
                        this.graph.labeled_negative() );
            this.algorithm_result.set_results( R );
        end
        
        function runMAD(this)
            mad = MAD;
            
            params.mu1 = 1;
            params.mu2 = 1;
            params.mu3 = 1;
            params.numIterations = this.numIterations;
            
            numVertices = this.graph.numVertices();
            numLabels   = this.graph.numLabels();
            Y = zeros( numVertices, numLabels);
            NEGATIVE = 1; POSITIVE = 2;
            Y( this.graph.labeled_negative(), NEGATIVE ) = 1;
            Y( this.graph.labeled_positive(), POSITIVE ) = 1;
            
            labeledVertices = this.graph.labeled();
            this.algorithm_result = MAD_Results;
            R = mad.run...
                ( this.graph.weights(), Y, params, labeledVertices );
            this.algorithm_result.set_results( R );
            this.set_numIterations( this.algorithm_result.numIterations() );
        end
    end % private methods
    
%********************** STATIC ***************************
    
    methods(Static)
        
        function curPos = getClickPosition()
            coordinates = get(gca,'CurrentPoint');
            %disp(coordinates));
            curPos.x = coordinates(1,1);
            curPos.y = coordinates(1,2);
        end

        function result = isLeftButton(button)
            result =  strcmpi(button,'normal');
        end
        
        function result = isRightButton(button)
            result =  strcmpi(button,'alt');
        end
        
        function addIconToUI(toolbar, iconName, tooltip, eventHandler)
            cdata = MainClass.loadIcon( iconName );
            
            uipushtool( toolbar,            ...
                        'cdata',            cdata, ...
                        'tooltip',          tooltip, ...
                        'ClickedCallback',  eventHandler);
        end
        
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

