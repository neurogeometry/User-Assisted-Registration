function gui_allignment_layout(control_panel, ha_source, ha_target, hf)
    elementHeight = 0.09;  
    elementWidth  = 0.45;
    marginY       = 0.0275;

    currentY      = 0.875;  

    fontSize = 10;

    % 2) Transformation Dropdown
    registrationTypes = {'select transform','translation + cpd','rigid + cpd','similarity + cpd','affine + cpd'};
    hregistrationType = uicontrol('Style', 'popupmenu', 'Parent', control_panel, ...
        'String', registrationTypes, 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight*1.1], ...
        'FontSize', fontSize);
    
    uicontrol('Style', 'pushbutton', ...
          'Parent', control_panel, ...
          'String', 'Toggle Images', ...
          'Units', 'normalized', ...
          'Position', [0.525, currentY, elementWidth, elementHeight*1.15], ...
          'FontSize', fontSize, ...
          'Callback', @(src,~) toggleImagesPushbutton(src, hf), ...
          'SelectionHighlight', 'off');
    
    currentY = currentY - elementHeight - marginY;
    
    % 3) Lambda
    uicontrol('Style', 'text', 'Parent', control_panel, ...
        'String', 'λ:', 'Units', 'normalized', ...
        'Position', [0.05, currentY-0.015, elementWidth*0.3, elementHeight], ...
        'FontSize', fontSize, 'HorizontalAlignment','left');

    hLambda = uicontrol('Style', 'edit', 'Parent', control_panel, ...
        'String', '0.5', 'Units', 'normalized', ...
        'Position', [0.175, currentY, 0.65/2, elementHeight], ...
        'FontSize', fontSize);

    % Intensity range adjustment
    uicontrol('Style', 'text', 'Parent', control_panel, 'String', 'Intensity Range:', ...
          'Units', 'normalized', 'Position', [0.525, currentY, elementWidth/2, elementHeight*0.8], ...
          'FontSize', fontSize);
    % Decide which image to use
    useTarget = isfield(hf.UserData, 'target_image') && ~isempty(hf.UserData.target_image);
    useSource = isfield(hf.UserData, 'source_image') && ~isempty(hf.UserData.source_image);
    if useTarget || useSource
        if useTarget
            % If both exist, this will run first
            theImage = hf.UserData.target_image;
        else
            % If we only have source
            theImage = hf.UserData.source_image;
        end
        
        % Compute intensity range
        max_int = intmax(class(theImage));
        min_int = intmin(class(theImage));
        intensityString = sprintf('[%d %d]', min_int, max_int);
    
        % Create edit box with default range
        uicontrol('Style', 'edit', 'Parent', control_panel, 'String', intensityString, ...
            'Units', 'normalized', 'Position', [0.75, currentY, elementWidth/2, elementHeight], ...
            'FontSize', fontSize, ...
            'Callback', @(src, ~) adjustIntensity(src, ha_source, ha_target));
    
        currentY = currentY - elementHeight - marginY;
    else
        % No valid image found
        uicontrol('Style', 'edit', 'Parent', control_panel, 'String', 'No Image Found', ...
            'Units', 'normalized', 'Position', [0.75, currentY, elementWidth/2, elementHeight], ...
            'FontSize', fontSize, ...
            'Callback', @(src, ~) adjustIntensity(src, ha_source, ha_target));
    
        currentY = currentY - elementHeight - marginY;
    end

    % 4) Sigma
    uicontrol('Style', 'text', 'Parent', control_panel, ...
        'String', 'σ:', 'Units', 'normalized', ...
        'Position', [0.05, currentY-0.015, elementWidth*0.3, elementHeight], ...
        'FontSize', fontSize, 'HorizontalAlignment','left');

    hSigma = uicontrol('Style', 'edit', 'Parent', control_panel, ...
        'String', hf.UserData.hSigma, 'Units', 'normalized', ...
        'Position', [0.175, currentY, 0.65/2, elementHeight], ...
        'FontSize', fontSize);


    currentY = currentY - elementHeight - marginY;

    % Point Selection Toggle
    hf.UserData.pointSelectionButton = uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Select Fiducial Points', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(src,~) togglePointSelection(hf, src));
    currentY = currentY - elementHeight - marginY;

    % Delete Points Toggle
    hf.UserData.deletePointsButton = uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Delete Fiducial Point Pair', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(src,~) toggleDeletePoints(hf, src));
    currentY = currentY - elementHeight - marginY;

    % Clear All Points Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Remove All Fiducial Points', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(~,~) clearAllPoints(hf));
    currentY = currentY - elementHeight - marginY;

    % Register Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Register', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(~,~) performRegistration(hf));

    

    currentY = currentY - elementHeight - marginY;

    %---------------------------------------------------------
    % BOTTOM ROW: Register (left), Save (right)
    %---------------------------------------------------------
    % Save Fiducial Points Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Save Points', ... % Two-line text
        'Units', 'normalized', ...
        'Position', [0.05, currentY, 0.215, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(~,~) saveData(hf));

    % Save Registered target Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Save Trace', ... % Two-line text
        'Units', 'normalized', ...
        'Position', [0.285, currentY, 0.215, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(~,~) saveRegisteredTrace(hf));


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    hf.UserData.hSigma   = hSigma;
    hf.UserData.hLambda  = hLambda;
    hf.UserData.registrationType = hregistrationType;

    % Helper functions for toggling and adjusting intensity
    hf.UserData.areImagesVisible = true;  % images start visible
    function toggleImagesPushbutton(~, hf)
        if hf.UserData.areImagesVisible
            % Turn images OFF
            set(findobj(hf.UserData.ha_source, 'Type', 'image'), 'Visible', 'off');
            set(findobj(hf.UserData.ha_target, 'Type', 'image'), 'Visible', 'off');
            hf.UserData.areImagesVisible = false;
        else
            % Turn images back ON
            set(findobj(hf.UserData.ha_source, 'Type', 'image'), 'Visible', 'on');
            set(findobj(hf.UserData.ha_target, 'Type', 'image'), 'Visible', 'on');
            hf.UserData.areImagesVisible = true;
        end
    end

    function adjustIntensity(src, ha1, ha2)
        range = str2num(src.String); %#ok<ST2NM>
        if numel(range) == 2
            clim(ha1, range);
            clim(ha2, range);
        else
            warning('Invalid intensity range');
        end
    end

   
    function toggleDeletePoints(hf, src)
        hf.UserData.isDeletingPoints = src.Value;
        if hf.UserData.isDeletingPoints
            disp('Delete Points mode: Click DIRECTLY on markers/lines and if that does not work, clear NEAR the points.');
            
            % Disable Point Selection
            if hf.UserData.isSelectingPoints
                hf.UserData.isSelectingPoints = false;
                set(hf.UserData.pointSelectionButton, 'Value', 0);
            end
            
            % Find all fiducial objects
            h_markers = findobj(hf.UserData.ha_combined, 'Tag', 'FiducialMarker');
            h_lines = findobj(hf.UserData.ha_combined, 'Tag', 'FiducialLine');
            
            % Enable interaction on markers/lines
            set([h_markers; h_lines], ...
                'PickableParts', 'all', ...
                'HitTest', 'on', ...
                'ButtonDownFcn', @(src,evt) deletePointsCallback(src, evt, hf));
            
            % Set axis callback for proximity-based deletion
            set(hf.UserData.ha_combined, 'ButtonDownFcn', @(src,evt) deletePointsCallback(src, evt, hf));
            
        else
            disp('Delete Points mode disabled.');
            
            % Disable interaction
            h_markers = findobj(hf.UserData.ha_combined, 'Tag', 'FiducialMarker');
            h_lines = findobj(hf.UserData.ha_combined, 'Tag', 'FiducialLine');
            set([h_markers; h_lines], ...
                'PickableParts', 'none', ...
                'HitTest', 'off', ...
                'ButtonDownFcn', '');
            set(hf.UserData.ha_combined, 'ButtonDownFcn', '');
        end
    end
    
    function deletePointsCallback(src, ~, hf)
        if ~hf.UserData.isDeletingPoints, return; end
        
        % Check if click was directly on a fiducial object
        clickedObj = get(hf, 'CurrentObject');
        if isgraphics(clickedObj) && isprop(clickedObj, 'UserData') && ~isempty(clickedObj.UserData)
            % Direct click on marker/line - use stored index
            pairIndex = clickedObj.UserData;
        else
            % Proximity-based click - find nearest pair
            cp = get(src, 'CurrentPoint');
            clickPos = cp(1,1:3);
            
            % Get all pairs' positions
            source_points = hf.UserData.sourcePoints;
            target_points = hf.UserData.targetPoints;
            nPairs = size(source_points, 1);
            
            % Find closest pair
            bestDist = inf;
            pairIndex = -1;
            for i = 1:nPairs
                distT = norm(target_points(i,:) - clickPos);
                distS = norm(source_points(i,:) - clickPos);
                thisDist = min(distT, distS);
                if thisDist < bestDist
                    bestDist = thisDist;
                    pairIndex = i;
                end
            end
            
            % Apply proximity threshold (e.g., 50 units)
            if pairIndex == -1 || bestDist > 50
                disp('No nearby pair found.');
                return;
            end
        end
    
        % Verify valid index
        if pairIndex < 1 || pairIndex > numel(hf.UserData.selectedPoints)
            return;
        end
    
        % Delete the pair
        delete(hf.UserData.selectedPoints{pairIndex}.sourceMarker);
        delete(hf.UserData.selectedPoints{pairIndex}.targetMarker);
        delete(hf.UserData.selectedPoints{pairIndex}.line);
        
        % Update data structures
        hf.UserData.selectedPoints(pairIndex) = [];
        hf.UserData.sourcePoints(pairIndex, :) = [];
        hf.UserData.targetPoints(pairIndex, :) = [];

        % Remove corresponding sourcePointIndices entry
        if isfield(hf.UserData, 'sourcePointIndices') && ~isempty(hf.UserData.sourcePointIndices)
            hf.UserData.sourcePointIndices(pairIndex) = [];  % This line was missing
        end
        
        % Reindex remaining pairs
        for i = 1:numel(hf.UserData.selectedPoints)
            hf.UserData.selectedPoints{i}.sourceMarker.UserData = i;
            hf.UserData.selectedPoints{i}.targetMarker.UserData = i;
            hf.UserData.selectedPoints{i}.line.UserData = i;
        end
    end

    % Modify togglePointSelection to disable Delete Points mode when activated
    function togglePointSelection(hf, src)
        hf.UserData.isSelectingPoints = src.Value;
        if hf.UserData.isSelectingPoints
            % Disable Delete Points mode if active
            if isfield(hf.UserData, 'isDeletingPoints') && hf.UserData.isDeletingPoints
                hf.UserData.isDeletingPoints = false;
                % Update Delete Points toggle button
                deletePointsButton = hf.UserData.deletePointsButton;
                if ishandle(deletePointsButton)
                    set(deletePointsButton, 'Value', 0);
                end
            end
            disp('Point selection enabled. Click on a point on the source trace and then the corresponding point on the target trace.');
        else
            disp('Point selection disabled.');
        end
    end


    function clearAllPoints(hf)
        if ~isempty(hf.UserData.selectedPoints)
            % Delete all markers and lines
            cellfun(@(pt) delete(pt.sourceMarker), hf.UserData.selectedPoints);
            cellfun(@(pt) delete(pt.targetMarker), hf.UserData.selectedPoints);
            cellfun(@(pt) delete(pt.line), hf.UserData.selectedPoints);
    
            % Clear selectedPoints array
            hf.UserData.selectedPoints = {};
    
            % Clear sourcePoints, targetPoints, and sourcePointIndices matrices
            hf.UserData.sourcePoints = [];
            hf.UserData.targetPoints = [];
            hf.UserData.sourcePointIndices = [];
        else
            disp('No points to clear.');
        end
    end
    
    function performRegistration(hf)
        % Retrieve target points
        target_points = hf.UserData.targetPoints;

        % Retrieve source points using indices from the original source trace
        source_indices = hf.UserData.sourcePointIndices;
        source_points = hf.UserData.r_source(source_indices, :);

        % Retrieve sigma, lambda, and method from the GUI
        sigma = hf.UserData.sigma;
        lambda = hf.UserData.lambda;

        % Validate sigma and lambda
        if isnan(sigma) || sigma <= 0
            errordlg('Sigma must be a positive number.', 'Invalid Input');
            return;
        end
        if isnan(lambda) || lambda < 0 || lambda > 1
            errordlg('Lambda must be a number between 0 and 1.', 'Invalid Input');
            return;
        end
        if isempty(source_points)
            errordlg('Please select points to register. ');
            return;
        end
    
        % Retrieve registration type and map to method
        regTypeOptions = get(hf.UserData.registrationType, 'String');
        regTypeIndex = get(hf.UserData.registrationType, 'Value');
        regTypeSelection = regTypeOptions{regTypeIndex};
    
        switch regTypeSelection
            case 'translation + cpd'
                method = 'translation+cpd';
            case 'rigid + cpd'
                method = 'rigid+cpd';
            case 'similarity + cpd'
                method = 'similarity+cpd';
            case 'affine + cpd'
                method = 'affine+cpd';
            otherwise
                errordlg('Select registration type.');
                return;
        end

        % Set plot flag to 0 for non-plotting
        plt = 0;

        % Reorder points for registration
        source_points_reordered = source_points(:, [2, 1, 3]);
        target_points_reordered = target_points(:, [2, 1, 3]);

        [T, ~, ~] = Register_linear_cpd3(source_points_reordered, target_points_reordered, sigma, lambda, method, plt);
        A = T.A;
        b = T.b;
        C_tilde = T.C_tilde;
        s=1;

        hf.UserData.A = A;
        hf.UserData.b = b;
        hf.UserData.C_tilde = C_tilde;
        hf.UserData.points = T.points;
        hf.UserData.method = T.method;

        % Apply transformation to the entire original source trace
        N = size(source_points_reordered, 1);
        D_source = pdist2(source_points_reordered, hf.UserData.r_source(:, [2,1,3]));
        G_source = exp(-D_source.^2 ./ (2 * sigma^2));
        V_source = -G_source' * C_tilde / N;
        r_source_registered = s .* hf.UserData.r_source(:, [2,1,3]) * A' + b + V_source;

        % Update UserData with the registered trace
        hf.UserData.r_source_registered = r_source_registered;

        % Update the combined plot
        updateCombinedPlot(hf, r_source_registered);
    end

    function updateCombinedPlot(hf, r_source_registered)
        % Clear only the data elements from the combined plot, retaining axis settings
        cla(hf.UserData.ha_combined);
        hold(hf.UserData.ha_combined, 'on');
        
        % Plot the target trace (original) in red with traceType 'target'
        plotAM(hf.UserData.target_AM, hf.UserData.r_target, [0, 0.5, 0.5], hf, 'target');
    
        % Plot the registered source trace in blue with traceType 'source'
        plotAM(hf.UserData.source_AM, r_source_registered, [1, 0.5, 0], hf, 'source');
    
        % Initialize selectedPoints
        hf.UserData.selectedPoints = {};
    
        % Plot all accumulated target and source points, and store handles
        target_points = hf.UserData.targetPoints;
        source_indices = hf.UserData.sourcePointIndices;
        source_points_registered = r_source_registered(source_indices, :);
        source_points_registered = source_points_registered(:, [2, 1, 3]);
        
        % source_points_registered = hf.UserData.sourcePoints;

        for i = 1:size(target_points, 1)
            % Plot target point (marker)
            targetMarker = plot3(hf.UserData.ha_combined, target_points(i,1), target_points(i,2), target_points(i,3), ...
                'k.', 'MarkerSize', 24, ...
                'Tag', 'FiducialMarker', 'UserData', i, ...  % Store index in UserData
                'PickableParts', 'all', 'HitTest', 'off'); 
        
            % Plot source point (marker)
            sourceMarker = plot3(hf.UserData.ha_combined, source_points_registered(i,1), source_points_registered(i,2), source_points_registered(i,3), ...
                'k.', 'MarkerSize', 24, ...
                'Tag', 'FiducialMarker', 'UserData', i, ...
                'PickableParts', 'all', 'HitTest', 'off');

            % Plot connecting line
            lineHandle = line(hf.UserData.ha_combined, [target_points(i,1), source_points_registered(i,1)], ...
                [target_points(i,2), source_points_registered(i,2)], [target_points(i,3), source_points_registered(i,3)], ...
                'Color', [0 0 0], 'LineStyle', '--', 'LineWidth', 1.5, ...
                'Tag', 'FiducialLine', 'UserData', i, ...
                'PickableParts', 'none', 'HitTest', 'off');
        
            % Store handles
            hf.UserData.selectedPoints{i} = struct(...
                'targetMarker', targetMarker, ...
                'sourceMarker', sourceMarker, ...
                'line', lineHandle);
        end
    
        % Refresh the plot view
        hold(hf.UserData.ha_combined, 'off');
        drawnow;
    end

    function saveData(hf)
        % Prompt user to choose file location and name
        [fileName, filePath] = uiputfile('*.mat', 'Save Data As');
        if isequal(fileName, 0) || isequal(filePath, 0)
            disp('Save canceled');
            return;
        end
    
        % Extract data to save
    
        % Target data
        r_source_original = hf.UserData.r_source_original;    % Original source points (unregistered)
    
        % Selected points
        targetPoints = hf.UserData.targetPoints;          % Selected target points
    
        % Retrieve sourcePoints corresponding to the unregistered source trace
        sourcePointIndices = hf.UserData.sourcePointIndices;  % Indices of selected source points
        sourcePoints_unregistered = r_source_original(sourcePointIndices, :);

        sourcePoints_unregistered=sourcePoints_unregistered(:, [2, 1, 3]);
        sourcePoints = sourcePoints_unregistered;

        Transformation.A = hf.UserData.A;
        Transformation.b = hf.UserData.b;
        Transformation.C_tilde = hf.UserData.C_tilde;
        Transformation.method = hf.UserData.method;
        Transformation.points = hf.UserData.points;
        Transformation.lambda = hf.UserData.lambda;
        Transformation.sigma = hf.UserData.sigma;
        
        % Save the data in the specified location
        save(fullfile(filePath, fileName), 'targetPoints', 'sourcePoints',  ...
             'Transformation');
        disp(['Data saved to ', fullfile(filePath, fileName)]);
    end

    function saveRegisteredTrace(hf)
        AM = hf.UserData.source_AM;
        r = hf.UserData.r_source_registered;    % Original source points (unregistered)
        R = hf.UserData.source_R;
        reduction_x = 1;
        reduction_y = 1;
        reduction_z = 1;

        if isempty(r)
            disp('No registered trace to save.');
            return;
        end


        formatList = {'SWC','MAT'};
        [ind, tf] = listdlg('ListString', formatList, ...
            'SelectionMode', 'single', ...
            'PromptString', 'Select a trace format to save:', ...
            'Name', 'Save Registered Trace', ...
            'ListSize', [200 70]);
        if ~tf
            disp('Save canceled.');
            return;
        end
        chosen = formatList{ind};

        switch chosen
            case 'SWC'
                swc_all = AM2swc(AM,r,R,reduction_x,reduction_y,reduction_z);
                [fileName, filePath] = uiputfile('*.swc', 'Save Registered Source As');
                if isequal(fileName, 0) || isequal(filePath, 0)
                    disp('Save canceled');
                    return;
                end            
                % Save the data in the specified location
                save(fullfile(filePath, fileName), 'swc_all');
                disp(['Data saved to ', fullfile(filePath, fileName)]);

            case 'MAT'
                [fileName, filePath] = uiputfile('*.mat', 'Save Registered Source As');
                if isequal(fileName, 0) || isequal(filePath, 0)
                    disp('Save canceled');
                    return;
                end            
                % Save the data in the specified location
                save(fullfile(filePath, fileName), 'AM', 'r', 'R', 'reduction_x', 'reduction_y', 'reduction_z');
                disp(['Data saved to ', fullfile(filePath, fileName)]);
        end
    
    end



end


