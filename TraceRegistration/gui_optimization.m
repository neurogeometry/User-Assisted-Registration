function gui_optimization(mode, data)

    thisFolder = fileparts(mfilename('fullpath'));
    
    % Create a path to ".." relative to thisFolder
    parentFolder = fullfile(thisFolder, '..');
    
    % Add that parentFolder to the path
    addpath(parentFolder);

    % Initialize main figure and panels using gui_allignment_defineframe
    hf = gui_allignment_defineframe();
    hf.Name = 'Trace Registration';

    hf.UserData.ha_combined       = hf.UserData.ha_combined;
    hf.UserData.isSelectingPoints = false;  % Initialize point selection as disabled
    hf.UserData.isDeletingPoints  = false;
    hf.UserData.selectedPoints    = {};     % Initialize selectedPoints as an empty cell array

    % Retrieve axes handles
    ha_source   = hf.UserData.ha_source;
    ha_target   = hf.UserData.ha_target;
    ha_combined = hf.UserData.ha_combined;
    control_panel = hf.UserData.control_panel;

    if strcmp(mode, 'new')
        % -----------------------------------------------------------
        %  NEW MODE: Load source & target from data.source_path, data.target_path
        % -----------------------------------------------------------
        % 1) Load the source
        [~, ~, source_ext] = fileparts(data.source_path);
        if strcmpi(source_ext, '.mat')
            source_data = load(data.source_path, 'Original', 'AM', 'r', 'R');
            hf.UserData.r_source   = source_data.r;
            hf.UserData.source_AM  = source_data.AM;
            hf.UserData.source_R  = source_data.R;
            if isfield(source_data, 'Original')
                hf.UserData.source_image = source_data.Original;
            end
        elseif strcmpi(source_ext, '.swc')
            [AMlbl, r, ~] = SWC2AM(data.source_path);
            hf.UserData.r_source   = r;
            hf.UserData.source_AM  = AMlbl;
            hf.UserData.source_R = zeros(size(r,1) ,1);
        else
            error('Unsupported file format for source. Must be .mat or .swc');
        end

        % 2) Load the target
        [~, ~, target_ext] = fileparts(data.target_path);
        if strcmpi(target_ext, '.mat')
            target_data = load(data.target_path, 'Original', 'AM', 'r', 'R');
            hf.UserData.r_target           = target_data.r;
            hf.UserData.r_target_original  = target_data.r;
            hf.UserData.target_AM          = target_data.AM;
            hf.UserData.target_R          = target_data.R;
            if isfield(target_data, 'Original')
                hf.UserData.target_image = target_data.Original;
            end
        elseif strcmpi(target_ext, '.swc')
            [AMlbl, r, ~] = SWC2AM(data.target_path);
            hf.UserData.r_target           = r;
            hf.UserData.r_target_original  = r;
            hf.UserData.target_AM          = AMlbl;
            hf.UserData.target_R = zeros(size(r,1) ,1);
        else
            error('Unsupported file format for target. Must be .mat or .swc');
        end

        % Initialize empty point lists
        hf.UserData.sourcePoints = [];
        hf.UserData.targetPoints = [];

    elseif strcmp(mode, 'loaded')
        % -----------------------------------------------------------
        %  LOADED MODE: 
        %     1) Load source & target from paths (like 'new')
        %     2) Override with saved data (AM_source, r_source, etc.)
        %     3) Plot the saved points
        % -----------------------------------------------------------

        % 1) Load the source from data.source_path
        [~, ~, source_ext] = fileparts(data.source_path);
        if strcmpi(source_ext, '.mat')
            source_data = load(data.source_path, 'Original', 'AM', 'r', 'R');
            hf.UserData.r_source   = source_data.r;
            hf.UserData.source_AM  = source_data.AM;
            hf.UserData.source_R          = source_data.R;
            if isfield(source_data, 'Original')
                hf.UserData.source_image = source_data.Original;
            end
        elseif strcmpi(source_ext, '.swc')
            [AMlbl, r, ~] = SWC2AM(data.source_path);
            hf.UserData.r_source   = r;
            hf.UserData.source_AM  = AMlbl;
            hf.UserData.source_R = zeros(size(r,1) ,1);
        else
            error('Unsupported file format for source. Must be .mat or .swc');
        end

        % 2) Load the target from data.target_path
        [~, ~, target_ext] = fileparts(data.target_path);
        if strcmpi(target_ext, '.mat')
            target_data = load(data.target_path, 'Original', 'AM', 'r', 'R');
            hf.UserData.r_target           = target_data.r;
            hf.UserData.r_target_original  = target_data.r;
            hf.UserData.target_AM          = target_data.AM;
            hf.UserData.target_R          = target_data.R;
            if isfield(target_data, 'Original')
                hf.UserData.target_image = target_data.Original;
            end
        elseif strcmpi(target_ext, '.swc')
            [AMlbl, r, ~] = SWC2AM(data.target_path);
            hf.UserData.r_target           = r;
            hf.UserData.r_target_original  = r;
            hf.UserData.target_AM          = AMlbl;
            hf.UserData.target_R = zeros(size(r,1) ,1);
        else
            error('Unsupported file format for target. Must be .mat or .swc');
        end

        % 3) Now override/merge with the saved data in 'data'
        if isfield(data, 'AM_source'),   hf.UserData.source_AM  = data.AM_source;   end
        if isfield(data, 'r_source'),    hf.UserData.r_source   = data.r_source;    end
        if isfield(data, 'AM_target'),   hf.UserData.target_AM  = data.AM_target;   end
        if isfield(data, 'r_target'),    hf.UserData.r_target   = data.r_target;    end

        % Original target stays the same unless you want to override it too:
        hf.UserData.r_target_original = hf.UserData.r_target;

        % 4) Points from saved data
        if isfield(data, 'sourcePoints'), hf.UserData.sourcePoints = data.sourcePoints; end
        if isfield(data, 'targetPoints'), hf.UserData.targetPoints = data.targetPoints; end

        hf.UserData.targetPoints = hf.UserData.targetPoints(:, [2, 1, 3]);
        [~, hf.UserData.targetPointIndices] = ismember(hf.UserData.targetPoints, hf.UserData.r_target, 'rows');
        hf.UserData.targetPoints = hf.UserData.targetPoints(:, [2, 1, 3]);

        % 5) If the transformation struct is there, store in hf.UserData
        if isfield(data, 'Transformation')
            T = data.Transformation;  % convenience
            hf.UserData.A       = T.A;
            hf.UserData.b       = T.b;
            hf.UserData.C_tilde = T.C_tilde;
            hf.UserData.method  = T.method;
            hf.UserData.points  = T.points;
            hf.UserData.lambda  = T.lambda;
            hf.UserData.sigma   = T.sigma;
        end

        % 6) If you still want to apply voxel_size or ppp, do so here
        % (Same logic as 'new', if you store them in data.voxel_size or data.ppp)
        if isfield(data, 'voxel_size') && ~isempty(data.voxel_size)
            voxel_size = data.voxel_size;
            hf.UserData.r_target(:,3)          = hf.UserData.r_target(:,3)          * voxel_size;
            hf.UserData.r_source(:,3)          = hf.UserData.r_source(:,3)          * voxel_size;
            hf.UserData.r_target_original(:,3) = hf.UserData.r_target_original(:,3) * voxel_size;
            hf.UserData.voxel_size = voxel_size;
        end

        if isfield(data, 'ppp') && ~isempty(data.ppp)
            ppp = data.ppp;
            [hf.UserData.source_AM, hf.UserData.r_source, ~] = ...
                AdjustPPM(hf.UserData.source_AM, hf.UserData.r_source, ...
                          zeros(length(hf.UserData.source_AM),1), ppp);
            [hf.UserData.target_AM, hf.UserData.r_target, ~] = ...
                AdjustPPM(hf.UserData.target_AM, hf.UserData.r_target, ...
                          zeros(length(hf.UserData.target_AM),1), ppp);
            hf.UserData.ppp = ppp;
        end

    else
        error('Invalid mode specified. Use "new" for new traces or "loaded" for saved session.');
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
    % set(hf.UserData.hSigma, 'String', );

    % 3) default transformation = 'select transform'
    hf.UserData.method = 'affine+cpd';

    % -----------------------------------------------------------
    % PLOTTING SECTION (applies to both 'new' and 'loaded')
    % -----------------------------------------------------------

    % --- Plot source axis
    if isfield(hf.UserData, 'source_image')
        axes(ha_source);
        source_img = hf.UserData.source_image;
        if ndims(source_img) == 3
            source_img = max(source_img, [], 3); % Use max projection for 3D images
        end
        imshow(source_img, [], 'Parent', ha_source);
        title(ha_source, 'Source'); % Ensure title is reset
        hold(ha_source, 'on'); % Keep current content and settings
        plotAM(hf.UserData.source_AM, hf.UserData.r_source, [1, 0.5, 0], hf, 'source');
    else
        axes(ha_source);
        title(ha_source, 'Source'); % Ensure title is reset
        axis equal; axis ij; hold on;
        plotAM(hf.UserData.source_AM, hf.UserData.r_source, [1, 0.5, 0], hf, 'source');
    end
    
    % --- Plot target axis
    if isfield(hf.UserData, 'target_image')
        axes(ha_target);
        target_img = hf.UserData.target_image;
        if ndims(target_img) == 3
            target_img = max(target_img, [], 3); % Use max projection for 3D images
        end
        imshow(target_img, [], 'Parent', ha_target);
        title(ha_target, 'Target'); % Ensure title is reset
        hold(ha_target, 'on'); % Keep current content and settings
        plotAM(hf.UserData.target_AM, hf.UserData.r_target, [0, 0.5, 0.5], hf, 'target');
    else
        axes(ha_target);
        title(ha_target, 'Target'); % Ensure title is reset
        axis equal; axis ij; hold on;
        plotAM(hf.UserData.target_AM, hf.UserData.r_target, [0, 0.5, 0.5], hf, 'target');
    end

    % --- Plot combined axis
    axes(ha_combined);
    axis equal; axis ij; hold(ha_combined, 'on');
    plotAM(hf.UserData.source_AM, hf.UserData.r_source, [1, 0.5, 0], hf, 'source');
    plotAM(hf.UserData.target_AM, hf.UserData.r_target, [0, 0.5, 0.5], hf, 'target');

    % If loading saved data, re-plot the selected points
    if strcmp(mode, 'loaded') && ~isempty(hf.UserData.sourcePoints)
        hf.UserData.selectedPoints = {};
        source_points = hf.UserData.sourcePoints;
        target_points = hf.UserData.targetPoints;

        for i = 1:size(source_points, 1)
            % Plot source point
            sourceMarker = plot3(hf.UserData.ha_combined, ...
                source_points(i, 1), source_points(i, 2), source_points(i, 3), ...
                '.', 'MarkerSize', 24, 'HitTest','off', 'PickableParts','all','MarkerFaceColor', [0, 0, 0], ...
                'MarkerEdgeColor', [0, 0, 0], 'Tag', 'FiducialMarker', 'UserData', i, 'DisplayName', 'source Point');


            % Plot target point
            targetMarker = plot3(hf.UserData.ha_combined, ...
                target_points(i, 1), target_points(i, 2), target_points(i, 3), ...
                'o', 'MarkerSize', 24, 'HitTest','off', 'PickableParts','all', 'MarkerFaceColor', [0, 0, 0], ...
                'MarkerEdgeColor', [0, 0, 0], 'Tag', 'FiducialMarker', 'UserData', i, 'DisplayName', 'target Point');

            % Connect them with a line
            lineHandle = line(hf.UserData.ha_combined, ...
                [source_points(i, 1), target_points(i, 1)], ...
                [source_points(i, 2), target_points(i, 2)], ...
                [source_points(i, 3), target_points(i, 3)], ...
                'Color', [0, 0, 0], 'LineStyle', '--', 'LineWidth', 1.5, 'Tag', 'FiducialLine', 'UserData', i, 'HitTest','off', 'PickableParts','none');

            hf.UserData.selectedPoints{i} = struct( ...
                'sourceMarker',  sourceMarker, ...
                'targetMarker',  targetMarker, ...
                'line',          lineHandle );
        end
    end

    % Initialize controls in control_panel using gui_allignment_layout
    gui_allignment_layout(control_panel, ha_source, ha_target, hf);

    % Add standard MATLAB figure toolbar buttons to the main figure
    addToolbarExplorationButtons(gcf);

end