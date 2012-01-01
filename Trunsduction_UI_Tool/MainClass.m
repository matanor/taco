classdef MainClass < handle
    %CLASS1 Summary of this class goes here
    %   Detailed explanation goes here
    % http://stackoverflow.com/questions/106086/in-matlab-can-a-class-method-act-as-a-uicontrol-callback-without-being-public
    
    properties (Access=public)
        graph;
    end

    properties (Access=private)
        figureHandle;
        iterations;
        plotInfo;
        numIterations;
        alpha;
        beta;
        labeledConfidence;
        leftButtonDownPosition;
%         rightButtonDownPosition;
    end

    methods
        function this = MainClass() % Constructor
            this.numIterations = 100;
            this.beta = 1;
            this.alpha = 1;
            this.labeledConfidence = 0.1;
        end
    end
    
%********************** Private Event Handlers ***************************

    methods (Access = private)
        
        function back(this, ~, ~)
            if (this.plotInfo.currentIter > 1)
                plotGraph(this, this.plotInfo.currentIter - 1);
            end
            disp('back');
        end
        
        function forward(this, ~, ~)
            if (this.plotInfo.currentIter < this.numIterations)
                plotGraph(this, this.plotInfo.currentIter + 1);
            end
            disp('forward');
        end
        
        function run(this, ~, ~)
            disp('run');
            this.runAlgorithm();
            this.plotInfo.currentIter = 1;
            plotGraph(this, this.plotInfo.currentIter);
        end
        
        function save(this, ~, ~)
            disp('save');
            fileName = uiputfile;
            if (0 ~= fileName)
                disp(['Saving to file: ' fileName]);
                graph = this.graph;
                save(fileName, 'graph' );
            end
        end
        
        function open(this, ~, ~)
            disp('open');
            fileName = uigetfile;
            if (0 ~= fileName)
                disp(['Opening file: ' fileName]);
                loadData = load(fileName, 'graph');
                this.graph = loadData.graph;
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
            
                existing_vertex = MainClass.findNearbyVertex ...
                    ( this.leftButtonDownPosition, ...
                      this.graph.v_coordinates );
                if (~isempty(existing_vertex))
                    disp('Error: can not add new vertex. too close to an existing vertex');
                    return;
                end
                addVertex( this, leftButtonUpPosition );
            else
                v1 = MainClass.findNearbyVertex ...
                        (   this.leftButtonDownPosition, ...
                            this.graph.v_coordinates );
                v2 = MainClass.findNearbyVertex ...
                        (   leftButtonUpPosition, ...
                            this.graph.v_coordinates );
                        
                if (~isempty(v1) && ~isempty(v2))
                    % two vertices - add adge
                    this.addEdge(v1, v2 );
                elseif (~isempty(v1) && isempty(v2))
                    % only source vertex - move it
                    this.moveVertex(v1, leftButtonUpPosition );
                end
            end
            this.leftButtonDownPosition = [];
            this.plotGraph(this.plotInfo.currentIter);
        end
        
        function deleteVertex(this, ~, ~)
            disp('deleteVertex');
            vertex_i = get(gco,'UserData');
            this.removeVertex( vertex_i );
            this.plotGraph(this.plotInfo.currentIter);
        end
        
        function deleteEdge(this,~,~)
            disp('deleteEdge');
            edgeVertices = get(gco,'UserData');
            this.removeEdge(edgeVertices(1), edgeVertices(2));
            this.plotGraph(this.plotInfo.currentIter);
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
        
        function updateIterations(this, ~, ~)
            disp('updateIterations');
            newValue = get(gco,'string');
            newNumericValue = str2double(newValue);
            if ceil(newNumericValue) == floor(newNumericValue)
                this.numIterations = newNumericValue;
            else
                disp(['Error: new value ' newValue ' is not an integer']);
            end
            this.run();
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

%********************** Private helpers ***************************

        function grPlot(this, V,E,vkind,ekind)
            %function h=grPlot(V,E,kind,vkind,ekind,sa) % Matan: removed figure handle
            % Function h=grPlot(V,E,kind,vkind,ekind,sa) 
            % draw the plot of the graph (digraph).
            % Input parameters: 
            %   V(n,2) or (n,3) - the coordinates of vertexes
            %     (1st column - x, 2nd - y) and, maybe, 3rd - the weights;
            %     n - number of vertexes.
            %     If V(n,2), we write labels: numbers of vertexes,
            %     if V(n,3), we write labels: the weights of vertexes.
            %     If V=[], use regular n-angle.
            %   E(m,2) or (m,3) - the edges of graph (arrows of digraph)
            %     and their weight; 1st and 2nd elements of each row 
            %     is numbers of vertexes;
            %     3rd elements of each row is weight of arrow;
            %     m - number of arrows.
            %     If E(m,2), we write labels: numbers of edges (arrows);
            %     if E(m,3), we write labels: weights of edges (arrows).
            %     For disconnected graph use E=[] or h=PlotGraph(V).
            %   kind - the kind of graph.
            %   kind = 'g' (to draw the graph) or 'd' (to draw digraph);
            %   (optional, 'g' default).
            %   vkind - kind of labels for vertexes (optional).
            %   ekind - kind of labels for edges or arrows (optional);
            %   For vkind and ekind use the format of function FPRINTF,
            %   for example, '%8.3f', '%14.10f' etc. Default value is '%d'.
            %   Use '' (empty string) for don't draw labels.

            wv=min(4,size(V,2)); % 3 for weighted vertexes %Matan: 4 for (mean, variance)
            vkind = lower(vkind);
            ekind = lower(ekind);
            numVertices = size(V,1);

            md=inf; % the minimal distance between vertexes
            for k1=1:numVertices-1,
              for k2=k1+1:numVertices,
                md=min(md,sum((V(k1,:)-V(k2,:)).^2)^0.5);
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
                edge = V( edgeVertices , 1:2); % numbers of vertexes 1, 2
                plot(edge(:,1),edge(:,2),'k-',      ...
                  'UserData'     , edgeVertices,   ... 
                  'ButtonDownFcn', {@(src, event)onButtonDown(this, src, event)});
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
            scatter( V(:,1), V(:,2), ... zeros(numVertices,1),...
                ones(numVertices, 1) * 40, V(:,3), ...
                'filled', ...
                'ButtonDownFcn', {@(src, event)onButtonDown(this, src, event)});
            colorbar;
%             plot(  V(:,1),V(:,2),'k.',  ...
%                 'MarkerSize',20,        ...
%                 'DisplayName','vertices',   ...
%                 'ButtonDownFcn', ...
%                 {@(src, event)onButtonDown(this, src, event)} );

            if ~isempty(vkind), % labels of vertexes
              for vertex_i=1:numVertices,
                if wv==3,
                  s=sprintf(vkind,V(vertex_i,3));
                elseif wv==4    % Matan: added option
                  s=sprintf(vkind,V(vertex_i,3),V(vertex_i,4));
                else
                  s=sprintf(vkind,vertex_i);
                end
                text(V(vertex_i,1)+0.05,V(vertex_i,2)-0.07,s, ...
                        'DisplayName', ['text_v_' num2str(vertex_i)], ...
                        'UserData'   , vertex_i );
              end
            end
            
            hold off
            axis off
        end

        function addVertex( this, position )
            old_num_vertices = size(this.graph.v_coordinates,1);
            disp(['Old num vertices: ' num2str(old_num_vertices)]);
            disp(['Adding vertex:(' num2str(position.x) ',' num2str(position.y) ')']);
            
            this.graph.v_coordinates = [this.graph.v_coordinates; ...
                                        position.x, position.y, 0, 0];
            this.graph.W = [this.graph.W; zeros(1,old_num_vertices)];
            this.graph.W = [this.graph.W  zeros(old_num_vertices+1,1)];
            
            %this.graph.v_coordinates 
            
            this.iterations.mu = [this.iterations.mu; ...
                                  zeros(1,this.numIterations)];
            this.iterations.v = [this.iterations.v; ...
                                  zeros(1,this.numIterations)];
                              
            new_num_vertices = size(this.graph.v_coordinates,1);
            disp(['New num vertices: ' num2str(new_num_vertices)]);
        end
        
        function removeVertex(this, vertex_i )
            disp('removeVertex');
            if (~isempty(vertex_i))
                updateVertexIndex(this, 'none', vertex_i)
                this.graph.v_coordinates(vertex_i,:)=[];
                this.graph.W(vertex_i,:)=[];
                this.graph.W(:,vertex_i)=[];
                this.iterations.mu(vertex_i,:)=[];
                this.iterations.v(vertex_i,:)=[];
            else
                disp('No nearby vertex');
            end
        end
        
        function moveVertex(this, v, newPosition)
            this.graph.v_coordinates(v,1) = newPosition.x;
            this.graph.v_coordinates(v,2) = newPosition.y;
        end
        
        function removeEdge(this, v1, v2)
            disp(['Removing edge between vertices ' ...
                    num2str(v1) ' ' num2str(v2)]);
            if (v1 == v2)
                disp('Error: Single node loop edge, skipping');
                return;
            end
            this.graph.W(v1, v2) = 0;
            this.graph.W(v2, v1) = 0;            
        end

        function addEdge(this, v1, v2 )
            disp(['Adding edge between vertices ' ...
                    num2str(v1) ' ' num2str(v2)]);
            if (v2 == v1)
                disp('Single node loop, skipping');
                return ;
            end
            this.graph.W(v1, v2) = 1;
            this.graph.W(v2, v1) = 1;
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
            
            positive = this.graph.labeled.positive;
            negative = this.graph.labeled.negative;
            
            % remove from positive and negative lists
            positive( positive == vertex_i ) = [];
            negative( negative == vertex_i ) = [];
            
            switch updateType
                case 'positive'
                    positive = [positive vertex_i];
                case 'negative'
                    negative = [negative vertex_i];
                case 'none'
                    
                otherwise
                    disp(['Error: unknown update type: ''' updateType ''''] );
                    
            end
            
            % update graph info
            this.graph.labeled.positive = positive;
            this.graph.labeled.negative = negative;
            
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
        
        function plotInfo = createPlotInfo(this)
            plotInfo = MainClass.createPlotInfo_ ...
                        (   this.graph.v_coordinates, ...
                            this.graph.W );
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
            editBoxPos.left = 30;
            editBoxPos.bottom = 0;
            editBoxPos.width = 100;
            editBoxPos.height = 20;
            margin = 5;
            
            MainClass.addParam( editBoxPos, 'iterations', this.numIterations, ...
                            @(src, event)updateIterations(this, src, event) );
            editBoxPos.left = editBoxPos.left + editBoxPos.width + margin;
            
            MainClass.addParam( editBoxPos, 'alpha', this.alpha, ...
                            @(src, event)updateAlpha(this, src, event) );
            editBoxPos.left = editBoxPos.left + editBoxPos.width + margin;
            
            MainClass.addParam( editBoxPos, 'beta', this.beta, ...
                            @(src, event)updateBeta(this, src, event) );
            editBoxPos.left = editBoxPos.left + editBoxPos.width + margin;
            
            MainClass.addParam( editBoxPos, 'labeled confidence', ... 
                            this.labeledConfidence, ...
                  @(src, event)updateLabeledConfidence(this, src, event) );
        end
    end % private methods
    
%********************** STATIC ***************************
    
    methods(Static)

        function closestVertex = findNearbyVertex( position, V )
            closestVertex = [];
            radius = 0.05;
            numVertices = size(V, 1);
            minDistance = 100^1000;
            for i=1:numVertices
                dx = position.x - V(i,1);
                dy = position.y - V(i,2);
                distance = sqrt( dx^2 + dy^2 );
                if (distance < minDistance && ...
                    distance < radius )
                    minDistance = distance;
                    closestVertex = i;
                end
            end
        end
        
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
        
        function plotInfo = createPlotInfo_(v_coordinates, W)
            plotInfo.Edges = MainClass.createEdges(W);
            plotInfo.v_coordinates = v_coordinates;
            plotInfo.currentIter = 1;
        end
        
        function addParam( editBoxPos, label, value, callback)
            margin = 5;
            labelPos = editBoxPos;
            labelPos.bottom = labelPos.bottom + editBoxPos.height + margin;
            uicontrol('style','text',...
                 'units','pix',...
                 'position',[labelPos.left  labelPos.bottom ...
                             labelPos.width labelPos.height],...
                 'string',label,...
                 'fontsize',8);

            uicontrol('style','edit',...
                 'units','pix',...
                 'position',[editBoxPos.left  editBoxPos.bottom ...
                             editBoxPos.width editBoxPos.height],...
                 'string',num2str(value),...
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
    
%********************** PUBLIC ***************************

    methods (Access = public)
        function runAlgorithm(this)          

            W = this.graph.W;
            
            num_vertices = size(W,1);
            disp(['runAlgorithm. num vertices: ' num2str(num_vertices)]);

            num_iter = this.numIterations;
            iteration.mu = zeros( num_vertices, num_iter );
            iteration.v = ones( num_vertices, num_iter );

            labeled.positive = this.graph.labeled.positive;
            labeled.negative = this.graph.labeled.negative;
            first_iteration = 1;

            iteration.mu( labeled.positive, first_iteration)  = +1;
            iteration.mu( labeled.negative, first_iteration ) = -1;

            iteration.v( labeled.positive, first_iteration)  ...
                = this.labeledConfidence;
            iteration.v( labeled.negative, first_iteration ) ...
                = this.labeledConfidence;

            beta = this.beta;
            alpha = this.alpha;

            % note iteration index starts from 2
            for iter_i = 2:num_iter

                prev_mu = iteration.mu( :, iter_i - 1) ;
                prev_v =  iteration.v ( :, iter_i - 1) ;

                for vertex_i=1:num_vertices
                    neighbours = find( W(vertex_i, :) ~= 0 );
                    ni = length(neighbours);
                    B = sum( prev_mu( neighbours ) );
                    C = sum( prev_mu( neighbours ) ./ prev_v( neighbours ) );
                    D = sum( 1 ./ prev_v( neighbours ) );
                    iteration.mu(vertex_i, iter_i) = ...
                        (B + prev_v(vertex_i) * C) / (ni + prev_v(vertex_i) * D);
                end

                iteration.mu( labeled.positive, iter_i)  = +1;
                iteration.mu( labeled.negative,  iter_i ) = -1;
                
                for vertex_i=1:num_vertices
                    neighbours = find( W(vertex_i, :) ~= 0 );
                    A = sum ( (prev_mu(vertex_i) - prev_mu( neighbours )).^2 );

                    iteration.v(vertex_i, iter_i) = ...
                        (beta + sqrt( beta^2 + 4 * alpha * A)) / (2 * alpha);
                end
                
                iteration.v( labeled.positive, iter_i) ...
                    = this.labeledConfidence;
                iteration.v( labeled.negative, iter_i ) ...
                    = this.labeledConfidence;

            end
            
            disp('size(iteration.v)=');
            disp(size(iteration.v));
            this.iterations = iteration;
        end
        
        function plotGraph(this, iter_i)

            disp(['plotGraph: ' num2str(iter_i)]);
            if (isempty( this.figureHandle ) )
                disp('Creating figure...');
                this.figureHandle  = createFigureToolbar(this);
                this.plotInfo = createPlotInfo(this);
                this.addParamsUI();
            end
            
            this.plotInfo.Edges = MainClass.createEdges(this.graph.W);
            this.plotInfo.v_coordinates = this.graph.v_coordinates;
            
%             disp(size(this.plotInfo.v_coordinates(:,3)));
%             disp(size(this.iterations.mu(:, iter_i)));
            this.plotInfo.v_coordinates(:,3) = this.iterations.mu(:, iter_i);
            this.plotInfo.v_coordinates(:,4) = this.iterations.v(:, iter_i);
            
            newplot;
            this.grPlot( this.plotInfo.v_coordinates,...
                    this.plotInfo.Edges, '(%6.4f,%6.4f)','');
                
            this.addVerticesContextMenu();
            this.addEdgesContextMenu();
            
            this.plotInfo.currentIter = iter_i;
            
            drawnow expose;
        end
     
    end % public methods

end

