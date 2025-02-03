function gui_optimization(mode, data)
    thisFolder = fileparts(mfilename('fullpath'));
    
    % Create a path to ".." relative to thisFolder
    parentFolder = fullfile(thisFolder, '..');
    
    % Add that parentFolder to the path
    addpath(parentFolder);
    % Initialize main figure and panels using gui_allignment_defineframe
    hf = gui_allignment_defineframe();
    hf.Name = 'Point Set Registration';

    hf.UserData.ha_combined       = hf.UserData.ha_combined;
    hf.UserData.isSelectingPoints = false;  % Initialize point selection as disabled
    hf.UserData.isDeletingPoints  = false;  % Initialize point deletion as disabled
    hf.UserData.selectedPoints    = {};     % Initialize selectedPoints as an empty cell array

    % Retrieve axes handles
    ha_source   = hf.UserData.ha_source;
    ha_target   = hf.UserData.ha_target;
    ha_combined = hf.UserData.ha_combined;
    control_panel = hf.UserData.control_panel;

    if strcmp(mode, 'new')
        % ---------- 1) Load the source ----------
        [~, ~, source_ext] = fileparts(data.source_path);
        switch lower(source_ext)
            case '.mat'
                % Load .mat file expecting 'r' (and optionally 'Original')
                source_data = load(data.source_path, 'Original', 'r');
                hf.UserData.r_source = source_data.r;
                hf.UserData.r_source_original = source_data.r;
                if isfield(source_data, 'Original')
                    hf.UserData.source_image = source_data.Original;
                end

            case '.txt'
                % Load Nx2 or Nx3 from text
                hf.UserData.r_source = loadTxtPoints(data.source_path);
                hf.UserData.r_source_original = loadTxtPoints(data.source_path);

            otherwise
                error('Unsupported file format for source. Must be .mat or .txt');
        end

        % ---------- 2) Load the target ----------
        [~, ~, target_ext] = fileparts(data.target_path);
        switch lower(target_ext)
            case '.mat'
                target_data = load(data.target_path, 'Original', 'r');
                hf.UserData.r_target          = target_data.r;
                
                if isfield(target_data, 'Original')
                    hf.UserData.target_image = target_data.Original;
                end

            case '.txt'
                hf.UserData.r_target          = loadTxtPoints(data.target_path);
                

            otherwise
                error('Unsupported file format for target. Must be .mat or .txt');
        end

        % Initialize empty point lists
        hf.UserData.sourcePoints = [];
        hf.UserData.targetPoints = [];

        % Store dimension info
        hf.UserData.dimsource = size(hf.UserData.r_source, 2);
        hf.UserData.dimtarget = size(hf.UserData.r_target, 2);

    elseif strcmp(mode, 'loaded')
        % ===========================================================
        %  LOADED MODE
        %     1) Load source & target from paths (like 'new')
        %     2) Override with saved data (r_source, r_target, etc.)
        %     3) Plot the saved points
        % ===========================================================

        % 1) Load the source
        [~, ~, source_ext] = fileparts(data.source_path);
        switch lower(source_ext)
            case '.mat'
                source_data = load(data.source_path, 'Original', 'r');
                hf.UserData.r_source = source_data.r;
                hf.UserData.r_source_original = source_data.r;
                if isfield(source_data,'Original')
                    hf.UserData.source_image = source_data.Original;
                end

            case '.txt'
                hf.UserData.r_source = loadTxtPoints(data.source_path);
                hf.UserData.r_source_original = hf.UserData.r_source;

            otherwise
                error('Unsupported file format for source. Must be .mat or .txt');
        end

        % 2) Load the target
        [~, ~, target_ext] = fileparts(data.target_path);
        switch lower(target_ext)
            case '.mat'
                target_data = load(data.target_path, 'Original', 'r');
                hf.UserData.r_target          = target_data.r;
                if isfield(target_data, 'Original')
                    hf.UserData.target_image = target_data.Original;
                end

            case '.txt'
                hf.UserData.r_target          = loadTxtPoints(data.target_path);

            otherwise
                error('Unsupported file format for target. Must be .mat or .txt');
        end

        % 3) Merge with saved data
        if isfield(data, 'r_source'), hf.UserData.r_source = data.r_source; end
        if isfield(data, 'r_target'), hf.UserData.r_target = data.r_target; end

        % Keep a copy of the original target
        hf.UserData.r_target_original = hf.UserData.r_target;

        hf.UserData.dimsource = size(hf.UserData.r_source,2);
        hf.UserData.dimtarget = size(hf.UserData.r_target,2);

        % 4) Points from saved data
        if isfield(data, 'sourcePoints'), hf.UserData.sourcePoints = data.sourcePoints; end
        if isfield(data, 'targetPoints'), hf.UserData.targetPoints = data.targetPoints; end

        % Map targetPoints to the correct indices
        if isfield(hf.UserData,'r_target') && ~isempty(hf.UserData.r_target)
            [~, hf.UserData.targetPointIndices] = ismember(hf.UserData.targetPoints, hf.UserData.r_target, 'rows');
        end

        % 5) If the transformation struct is there, store it
        if isfield(data, 'Transformation')
            T = data.Transformation;
            hf.UserData.A       = T.A;
            hf.UserData.b       = T.b;
            hf.UserData.C_tilde = T.C_tilde;
            hf.UserData.method  = T.method;
            hf.UserData.points  = T.points;
            hf.UserData.lambda  = T.lambda;
            hf.UserData.sigma   = T.sigma;
        end

    else
        error('Invalid mode specified. Use "new" for new or "loaded" for saved session.');
    end

    %--------------------------------------------------
    % Now set DEFAULTS for lambda, sigma, method
    %--------------------------------------------------
    % 1) lambda = 0.5
    hf.UserData.lambda = 0.5;

    % 2) sigma = round(max(size(source_image)) / 10)
    targSize = size(hf.UserData.r_source,1);
    sVal = round(max(targSize)/10);
    hf.UserData.sigma = sVal;
    hf.UserData.hSigma = num2str(sVal);

    % 3) default transformation = 'select transform'
    hf.UserData.method = 'affine+cpd';

    % ===========================================================
    %  PLOTTING SECTION (applies to both 'new' and 'loaded')
    % ===========================================================

    % Plot source on ha_source
    if isfield(hf.UserData, 'source_image')
        axes(ha_source);
        source_img = hf.UserData.source_image;
        if ndims(source_img) == 3
            source_img = max(source_img, [], 3);
        end
        imshow(source_img, [], 'Parent', ha_source);
        axis equal; hold(ha_source, 'on');
        plotAM([], hf.UserData.r_source, [1, 0.5, 0], hf, 'source');
    else
        axes(ha_source);
        axis equal; hold on;
        plotAM([], hf.UserData.r_source, [1, 0.5, 0], hf, 'source');
    end

    % Plot target on ha_target
    if isfield(hf.UserData, 'target_image')
        axes(ha_target);
        target_img = hf.UserData.target_image;
        if ndims(target_img) == 3
            target_img = max(target_img, [], 3);
        end
        imshow(target_img, [], 'Parent', ha_target);
        axis equal; hold(ha_target, 'on');
        plotAM([], hf.UserData.r_target, [0, 0.5, 0.5], hf, 'target');
    else
        axes(ha_target);
        axis equal; hold on;
        plotAM([], hf.UserData.r_target, [0, 0.5, 0.5], hf, 'target');
    end

    % Plot both on ha_combined
    axes(ha_combined);
    disableDefaultInteractivity(ha_combined);
    axis equal; hold(ha_combined, 'on');
    plotAM([], hf.UserData.r_source, [1, 0.5, 0], hf, 'source');
    plotAM([], hf.UserData.r_target, [0, 0.5, 0.5], hf, 'target');

    if strcmp(mode,'loaded') && ~isempty(hf.UserData.sourcePoints)
        hf.UserData.selectedPoints = {};
        Spts = hf.UserData.sourcePoints;
        Tpts = hf.UserData.targetPoints;

        for i=1:size(Tpts,1)
            if hf.UserData.dimsource==2
                % 2D plot
                hT = plot(hf.UserData.ha_combined, Tpts(i,1),Tpts(i,2), '.',...
                    'MarkerSize',24,'MarkerFaceColor',[0,0,0],...
                    'Tag', 'FiducialMarker', 'UserData', i, ...  % Store index in UserData
                    'PickableParts', 'all', 'HitTest', 'off', ... % Enable interaction
                    'MarkerEdgeColor',[0,0,0]);
            else
                % 3D
                hT = plot3(hf.UserData.ha_combined, Tpts(i,1),Tpts(i,2),Tpts(i,3), '.',...
                    'MarkerSize',24,'MarkerFaceColor',[0,0,0],...
                    'Tag', 'FiducialMarker', 'UserData', i, ...  % Store index in UserData
                    'PickableParts', 'all', 'HitTest', 'off', ... % Enable interaction
                    'MarkerEdgeColor',[0,0,0]);
            end
            

            if hf.UserData.dimtarget==2
                hS = plot(hf.UserData.ha_combined, Spts(i,1),Spts(i,2), '.',...
                    'MarkerSize',24,'MarkerFaceColor',[0,0,0],...
                    'Tag', 'FiducialMarker', 'UserData', i, ...  % Store index in UserData
                    'PickableParts', 'all', 'HitTest', 'off', ... % Enable interaction
                    'MarkerEdgeColor',[0,0,0]);
                L = line([Tpts(i,1),Spts(i,1)], ...
                         [Tpts(i,2),Spts(i,2)], ...
                         'Tag', 'FiducialLine', 'UserData', i, 'HitTest','off', 'PickableParts','none', ...
                         'LineStyle','--','Color',[0,0,0],'LineWidth',1.5);
            else
                hS = plot3(hf.UserData.ha_combined, Spts(i,1),Spts(i,2),Spts(i,3), '.',...
                    'MarkerSize',24,'MarkerFaceColor',[0,0,0],...
                    'Tag', 'FiducialMarker', 'UserData', i, ...  % Store index in UserData
                    'PickableParts', 'all', 'HitTest', 'off', ... % Enable interaction
                    'MarkerEdgeColor',[0,0,0]);
                L = line([Tpts(i,1),Spts(i,1)], ...
                         [Tpts(i,2),Spts(i,2)], ...
                         [Tpts(i,3),Spts(i,3)], ...
                         'Tag', 'FiducialLine', 'UserData', i, 'HitTest','off', 'PickableParts','none', ...
                         'LineStyle','--','Color',[0,0,0],'LineWidth',1.5);
            end



            hf.UserData.selectedPoints{i} = struct('sourceMarker',hS,'targetMarker',hT,'line',L);
        end
    end

    % Initialize controls in control_panel using gui_allignment_layout
    gui_allignment_layout(control_panel, ha_source, ha_target, hf);

    % Add standard MATLAB figure toolbar buttons
    addToolbarExplorationButtons(gcf);
end

% Helper: read Nx2 or Nx3 from a .txt
function r = loadTxtPoints(filepath)
    % This uses "readmatrix" if available (R2019b+).
    % Otherwise, you can use dlmread or load(...,'-ascii')
    if exist('readmatrix','file')
        r = readmatrix(filepath);
    else
        r = dlmread(filepath);
    end

    if size(r,2) < 2 || size(r,2) > 3
        error('Text file must have Nx2 or Nx3 numeric data.');
    end
end
