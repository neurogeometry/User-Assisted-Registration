function gui_optimization_image(mode, data)
    thisFolder = fileparts(mfilename('fullpath'));
    
    % Create a path to ".." relative to thisFolder
    parentFolder = fullfile(thisFolder, '..');
    
    % Add that parentFolder to the path
    addpath(parentFolder);
    % Initialize main figure
    hf_main = figure('Name', 'Image Registration', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...           % Remove the main menubar
        'ToolBar', 'none', ...           % Remove the main figure toolbar
        'Position', [100, 200, 800, 600]);

    % Create axes for source and target
    ha_source = axes('Parent', hf_main, 'Units', 'normalized', ...
                     'Position', [0.05, 0.2, 0.4, 0.75]);
    ha_target = axes('Parent', hf_main, 'Units', 'normalized', ...
                     'Position', [0.55, 0.2, 0.4, 0.75]);

    % addToolbarExplorationButtons(gcf);

    axtoolbar(ha_source, {'zoomin','zoomout','pan','restoreview'});
    axtoolbar(ha_target, {'zoomin','zoomout','pan','restoreview'});

    % Create a separate figure for controls
    hf_controls = figure('Name', 'Controls', ...
                         'NumberTitle', 'off', ...
                         'MenuBar', 'none','Resize','off');
    hf_controls.Position = [920, 300, 225, 270];

    % Create a panel in the control figure
    control_panel = uipanel('Parent', hf_controls, 'Units','pixels',...
                            'Position', [10, 10, 210, 260], ...
                            'Title', 'Controls','FontSize', 10);

    %--------------------------------------------------
    % Store key handles in UserData
    %--------------------------------------------------
    hf_main.UserData.ha_source         = ha_source;
    hf_main.UserData.ha_target         = ha_target;
    hf_main.UserData.hf_controls       = hf_controls;
    hf_main.UserData.isSelectingPoints = false;
    hf_main.UserData.isDeletingPoints  = false;
    hf_main.UserData.selectedPoints    = {};
    hf_main.UserData.sourceMarkers     = [];
    hf_main.UserData.targetMarkers     = [];
    hf_main.UserData.pointColors       = [];

    %--------------------------------------------------
    % Load images (new or loaded)
    %--------------------------------------------------
    if strcmp(mode, 'new')
        hf_main.UserData.source_image = loadOrRead(data.source_path);
        hf_main.UserData.target_image = loadOrRead(data.target_path);

        hf_main.UserData.sourcePoints = [];
        hf_main.UserData.targetPoints = [];
        hf_main.UserData.pointColors  = [];

    elseif strcmp(mode, 'loaded')
        hf_main.UserData.source_image = loadOrRead(data.source_path);
        hf_main.UserData.target_image = loadOrRead(data.target_path);

        if isfield(data, 'Transformation')
            hf_main.UserData.Transformation = data.Transformation;
            hf_main.UserData.method    = data.Transformation.method;
            hf_main.UserData.A         = data.Transformation.A;
            hf_main.UserData.b         = data.Transformation.b;
            hf_main.UserData.C_tilde   = data.Transformation.C_tilde;
            hf_main.UserData.points    = data.Transformation.points;
            hf_main.UserData.lambda    = data.Transformation.lambda;
            hf_main.UserData.sigma     = data.Transformation.sigma;
        end

        if isfield(data, 'source_points')
            hf_main.UserData.sourcePoints = data.source_points;
        else
            hf_main.UserData.sourcePoints = [];
        end

        if isfield(data, 'target_points')
            hf_main.UserData.targetPoints = data.target_points;
        else
            hf_main.UserData.targetPoints = [];
        end

        if isfield(data, 'pointColors')
            hf_main.UserData.pointColors = data.pointColors;
        else
            hf_main.UserData.pointColors = [];
        end

    else
        error('Invalid mode. Use "new" or "loaded".');
    end

    %--------------------------------------------------
    % Prepare figure displays
    %--------------------------------------------------
    source_dims = ndims(hf_main.UserData.source_image);
    target_dims = ndims(hf_main.UserData.target_image);

    hf_main.UserData.source_z  = 1;
    hf_main.UserData.target_z  = 1;

    if source_dims == 3
        hf_main.UserData.source_num_slices = size(hf_main.UserData.source_image, 3);
    else
        hf_main.UserData.source_num_slices = 1;
    end
    if target_dims == 3
        hf_main.UserData.target_num_slices = size(hf_main.UserData.target_image, 3);
    else
        hf_main.UserData.target_num_slices = 1;
    end

    %-------------- Display source --------------
    axes(ha_source); set(ha_source, 'NextPlot', 'add'); cla(ha_source);
    if hf_main.UserData.source_num_slices > 1
        hImgSource = imagesc(hf_main.UserData.source_image(:,:,hf_main.UserData.source_z));
        colormap(ha_source, gray);
    else
        hImgSource = imagesc(hf_main.UserData.source_image);
        colormap(ha_source, gray);
    end
    axis image; title('Source');
    hf_main.UserData.hImgSource = hImgSource;
    set(hImgSource, 'HitTest', 'on', 'PickableParts', 'all');
    % set(ha_source, 'HitTest', 'off');


    %-------------- Display target --------------
    axes(ha_target); set(ha_target, 'NextPlot', 'add'); cla(ha_target);
    if hf_main.UserData.target_num_slices > 1
        hImgTarget = imagesc(hf_main.UserData.target_image(:,:,hf_main.UserData.target_z));
        colormap(ha_target, gray);
    else
        hImgTarget = imagesc(hf_main.UserData.target_image);
        colormap(ha_target, gray);
    end
    axis image; title('Target');
    hf_main.UserData.hImgTarget = hImgTarget;
    set(hImgTarget, 'HitTest', 'on', 'PickableParts', 'all');
    %set(ha_target, 'HitTest', 'off');

    % If 3D, add sliders
    if hf_main.UserData.source_num_slices > 1
        hf_main.UserData.source_slider = uicontrol('Parent', hf_main, 'Style','slider',...
            'Units','normalized', 'Position',[0.05, 0.15, 0.4, 0.05], ...
            'Min',1, 'Max', hf_main.UserData.source_num_slices, 'Value',1, ...
            'SliderStep', [1/(hf_main.UserData.source_num_slices-1) , 1], ...
            'Callback', @(src, evt) updateSourceSlice(src, evt, hf_main));
        hf_main.UserData.source_z_text = uicontrol('Parent', hf_main, 'Style','text',...
            'Units','normalized', 'Position',[0.05, 0.2, 0.4, 0.03], ...
            'String','Z = 1', 'HorizontalAlignment','center');
    end

    if hf_main.UserData.target_num_slices > 1
        hf_main.UserData.target_slider = uicontrol('Parent', hf_main, 'Style','slider',...
            'Units','normalized', 'Position',[0.55, 0.15, 0.4, 0.05], ...
            'Min',1, 'Max', hf_main.UserData.target_num_slices, 'Value',1, ...
            'SliderStep', [1/(hf_main.UserData.target_num_slices-1) , 1], ...
            'Callback', @(src, evt) updateTargetSlice(src, evt, hf_main));
        hf_main.UserData.target_z_text = uicontrol('Parent', hf_main, 'Style','text',...
            'Units','normalized', 'Position',[0.55, 0.2, 0.4, 0.03], ...
            'String','Z = 1', 'HorizontalAlignment','center');
    end

    %--------------------------------------------------
    % Create the controls in the separate figure
    %--------------------------------------------------
    gui_allignment_layout_separate_controls(control_panel, hf_main);

    %--------------------------------------------------
    % Now set DEFAULTS for lambda, sigma, method
    %--------------------------------------------------
    % 1) lambda = 0.5
    hf_main.UserData.lambda = 0.5;
    set(hf_main.UserData.hLambda, 'String', '0.5');

    % 2) sigma = round(max(size(source_image)) / 10)
    targSize = size(hf_main.UserData.source_image);
    sVal = round(max(targSize)/10);
    hf_main.UserData.sigma = sVal;
    set(hf_main.UserData.hSigma, 'String', num2str(sVal));

    % 3) default transformation = 'select transform'
    set(hf_main.UserData.hRegType, 'Value', 1);
    hf_main.UserData.method = 'affine+cpd';

    %--------------------------------------------------
    % 4) Intensity Range: [minInt, maxInt]
    %--------------------------------------------------
    minInt = double(min(hf_main.UserData.source_image(:)));
    maxInt = double(max(hf_main.UserData.source_image(:)));
    clim(hf_main.UserData.ha_source, [minInt, maxInt]);
    clim(hf_main.UserData.ha_target, [minInt, maxInt]);
    createIntensityPanel(hf_main, [minInt, maxInt]);

    %--------------------------------------------------
    % If 'loaded', re-plot the saved point pairs
    %--------------------------------------------------
    if strcmp(mode, 'loaded') && ~isempty(hf_main.UserData.sourcePoints)
        nPoints = size(hf_main.UserData.sourcePoints,1);
        for i = 1:nPoints
            tPt  = hf_main.UserData.sourcePoints(i,:);
            sPt  = hf_main.UserData.targetPoints(i,:);
            if ~isempty(hf_main.UserData.pointColors)
                color_ = hf_main.UserData.pointColors(i,:);
            else
                color_ = rand(1,3);
            end

            axes(ha_source); hold on;
            ht = plot(tPt(1), tPt(2), '.', 'MarkerSize',12, 'LineWidth',2, 'Color', color_);
            axes(ha_target); hold on;
            hs = plot(sPt(1), sPt(2), '.', 'MarkerSize',12, 'LineWidth',2, 'Color', color_);

            hf_main.UserData.sourceMarkers(i) = ht;
            hf_main.UserData.targetMarkers(i) = hs;
        end
    end
end

%======================================================================
function createIntensityPanel(hf_main, defaultRange)
    % defaultRange is [minInt, maxInt]
    intensityPanel = uipanel('Parent', hf_main, 'Title','Intensity Range [min max]:', ...
        'Units','normalized','Position',[0.05, 0.05, 0.4, 0.07]);

    % uicontrol('Style','text','Parent',intensityPanel,...
    %     'Units','normalized','Position',[0.01,0.15,0.3,0.7],...
    %     'String','[min max]:','HorizontalAlignment','left');

    hEdit = uicontrol('Style','edit','Parent',intensityPanel,...
        'Units','normalized','Position',[0.35,0.15,0.55,0.7],...
        'Callback',@(src,evt) updateCaxis(src,evt,hf_main),...
        'String', sprintf('[%.0f %.0f]', defaultRange(1), defaultRange(2)) );

    hf_main.UserData.hEditIntensity = hEdit;
end

%======================================================================
function updateCaxis(src,~,hf_main)
    strVal = src.String;
    vals = str2num(strVal); %#ok<ST2NM>
    if numel(vals)==2
        clim(hf_main.UserData.ha_source, vals);
        clim(hf_main.UserData.ha_target, vals);
        disp(['Updated intensity range to [', num2str(vals), '].']);
    else
        warning('Invalid intensity range. Expect 2 numbers [min max].');
    end
end

%======================================================================
function I = loadOrRead(filename)
    if isfolder(filename)
        I = loadTifFolderAsStack(filename);
    else
        [~,~,ext] = fileparts(filename);
        switch lower(ext)
            case '.mat'
                temp = load(filename, 'Original');
                I = temp.Original;
            case {'.tif','.tiff'}
                info = imfinfo(filename);
                numFrames = numel(info);
                if numFrames > 1
                    width  = info(1).Width;
                    height = info(1).Height;
                    I = zeros(height, width, numFrames, ...
                        'like', imread(filename, 'Index', 1));
                    for k = 1:numFrames
                        I(:,:,k) = imread(filename, 'Index', k);
                    end
                else
                    I = imread(filename);
                    if ndims(I)==3 && size(I,3)==3
                        I = rgb2gray(I);
                    end
                end
            otherwise
                I = imread(filename);
                if ndims(I)==3 && size(I,3)==3
                    I = rgb2gray(I);
                end
        end
    end
end

function I = loadTifFolderAsStack(folderPath)
    folderPath = strcat(folderPath,'\');
    reduction_x = 1;
    reduction_y = 1;
    reduction_z = 1;
    reduct_method = 'Max';

    tifList = dir(fullfile(folderPath, '*.tif'));
    if isempty(tifList)
        error('No .tif files found in %s', folderPath);
    end

    fileNames = {tifList.name};
    baseNames = regexprep(fileNames, '\.tif(f)?$', '');
    numericVals = str2double(baseNames);
    [~, idx] = sort(numericVals);
    fileNames = fileNames(idx);

    I = ImportStackJ(folderPath, fileNames, ...
        reduction_x, reduction_y, reduction_z, reduct_method);
end
