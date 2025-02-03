function gui_allignment_layout_separate_controls(control_panel, hf_main)
    elementHeight = 0.09;  
    elementWidth  = 0.9;
    marginY       = 0.0275;

    % Start a bit lower than 1 so that the label doesn't get cut off
    currentY      = 0.875;  

    fontSize = 10;

    %---------------------------------------------------------
    % SECTION A (Transformation)
    %---------------------------------------------------------

    % 2) Transformation Dropdown
    registrationTypes = {'select transform','translation + cpd','rigid + cpd','similarity + cpd','affine + cpd'};
    hRegType = uicontrol('Style', 'popupmenu', 'Parent', control_panel, ...
        'String', registrationTypes, 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight*1.1], ...
        'FontSize', fontSize);
    currentY = currentY - elementHeight - marginY;

    % 3) Lambda
    uicontrol('Style', 'text', 'Parent', control_panel, ...
        'String', 'λ:', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth*0.3, elementHeight], ...
        'FontSize', fontSize, 'HorizontalAlignment','left');

    hLambda = uicontrol('Style', 'edit', 'Parent', control_panel, ...
        'String', '0.5', 'Units', 'normalized', ...
        'Position', [0.3, currentY, 0.65, elementHeight], ...
        'FontSize', fontSize);
    currentY = currentY - elementHeight - marginY;

    % 4) Sigma
    uicontrol('Style', 'text', 'Parent', control_panel, ...
        'String', 'σ:', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth*0.3, elementHeight], ...
        'FontSize', fontSize, 'HorizontalAlignment','left');

    hSigma = uicontrol('Style', 'edit', 'Parent', control_panel, ...
        'String', '10', 'Units', 'normalized', ...
        'Position', [0.3, currentY, 0.65, elementHeight], ...
        'FontSize', fontSize);
    currentY = currentY - elementHeight - marginY;

    %---------------------------------------------------------
    % SECTION B (Point selection / deletion)
    %---------------------------------------------------------
    % Point Selection Toggle
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Select Fiducial Points', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(src,~) togglePointSelection(hf_main, src), 'SelectionHighlight', 'off');
    currentY = currentY - elementHeight - marginY;

    % Delete Points Toggle
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Delete Fiducial Point Pair', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(src,~) toggleDeletePoints(hf_main, src), 'SelectionHighlight', 'off');
    currentY = currentY - elementHeight - marginY;

    % Clear All Points Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Remove All Fiducial Points', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(~,~) clearAllPoints(hf_main), 'SelectionHighlight', 'off');
    currentY = currentY - elementHeight - marginY;

    % Register Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Register', 'Units', 'normalized', ...
        'Position', [0.05, currentY, elementWidth, elementHeight], ...
        'FontSize', fontSize, ...
        'Callback', @(~,~) performRegistration(hf_main), 'SelectionHighlight', 'off');

    currentY = currentY - elementHeight - marginY;

    %---------------------------------------------------------
    % BOTTOM ROW: Register (left), Save (right)
    %---------------------------------------------------------
    % Save Fiducial Points Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Save Points', ... % Two-line text
        'Units', 'normalized', ...
        'Position', [0.05, currentY, 0.425, elementHeight], ... % Increased height
        'FontSize', fontSize, ...
        'Callback', @(~,~) saveData(hf_main), 'SelectionHighlight', 'off');

    % Save Registered target Button
    uicontrol('Style', 'pushbutton', 'Parent', control_panel, ...
        'String', 'Save Image', ... % Two-line text
        'Units', 'normalized', ...
        'Position', [0.525, currentY, 0.425, elementHeight], ... % Increased height
        'FontSize', fontSize, ...
        'Callback', @(~,~) saveRegisteredImage(hf_main), 'SelectionHighlight', 'off');

    %-----------------------------------------------
    % Store handles in hf_main.UserData for access
    %-----------------------------------------------
    hf_main.UserData.hSigma   = hSigma;
    hf_main.UserData.hLambda  = hLambda;
    hf_main.UserData.hRegType = hRegType;

    function performRegistration(hf_main)
        % Retrieve target and source points from UserData
        target_points = hf_main.UserData.targetPoints;
        source_points = hf_main.UserData.sourcePoints;
    
        % Retrieve sigma and lambda from the GUI
        sigma_str = get(hf_main.UserData.hSigma, 'String');
        lambda_str = get(hf_main.UserData.hLambda, 'String');
        sigma = str2double(sigma_str);
        lambda = str2double(lambda_str);
        hf_main.UserData.sigma = sigma;
        hf_main.UserData.lambda = lambda;
    
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
        regTypeOptions = get(hf_main.UserData.hRegType, 'String');
        regTypeIndex = get(hf_main.UserData.hRegType, 'Value');
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
    

        % Add a third dimension for consistency if the image is not a stack.
        sizeX=size(hf_main.UserData.source_image);
        if length(sizeX)==2
            source_points_reordered = source_points(:, [2, 1]); % Reorder to (x, y)
            target_points_reordered = target_points(:, [2, 1]); % Reorder to (x, y)
            % source_points_reordered = [source_points_reordered, ones(size(source_points_reordered, 1), 1)];
            % target_points_reordered = [target_points_reordered, ones(size(target_points_reordered, 1), 1)];
        elseif length(sizeX)==3
            source_points_reordered = source_points(:, [2, 1, 3]); % Reorder to (x, y)
            target_points_reordered = target_points(:, [2, 1, 3]); % Reorder to (x, y)
        end
        % Run registration function inverse for images.
        [T, ~, ~] = Register_linear_cpd3(target_points_reordered,source_points_reordered,  sigma, lambda, method, 0);
        A = T.A;
        b = T.b;
        C_tilde = T.C_tilde;
        hf_main.UserData.A = A;
        hf_main.UserData.b = b;
        hf_main.UserData.C_tilde = C_tilde;
        hf_main.UserData.points = T.points;
        hf_main.UserData.method = T.method;
        
        if length(sizeX)==2
            % Apply transformation to the source image
            type = '2D_images';
            registered_image = Perform_Registering_Transform(hf_main.UserData.source_image, type, T);
            % Update UserData with the registered image
            hf_main.UserData.registered_image = registered_image;


            % Display the fused image using imfuse in a new figure window
            fused_image = imfuse(hf_main.UserData.target_image, registered_image, 'falsecolor','Scaling','joint','ColorChannels',[1 2 0]);
            % Create a new figure window for the fused image
            figure('Name', 'Fused Image', 'NumberTitle', 'off');
            imshow(fused_image)
            title('Overlay of Target (Red) and Registered Source (Green) Images');
        end
        if length(sizeX) == 3
            % Apply transformation to the source image
            type = '3D_images';
            registered_image = Perform_Registering_Transform(hf_main.UserData.source_image, type, T);
            % Update UserData with the registered image
            hf_main.UserData.registered_image = registered_image;


            target_image = hf_main.UserData.target_image;
            % Get the sizes of the target and registered images
            target_size = size(target_image);
            registered_size = size(registered_image);
            
            % Determine the maximum size in each dimension
            max_size = max(target_size, registered_size);
    
            % Pad the target image to match the larger size
            padded_target = zeros(max_size, 'like', target_image); % Preserve the same data type
            padded_target(1:target_size(1), 1:target_size(2), 1:target_size(3)) = target_image;
            
            % Pad the registered image to match the larger size
            padded_registered = zeros(max_size, 'like', registered_image); % Preserve the same data type
            padded_registered(1:registered_size(1), 1:registered_size(2), 1:registered_size(3)) = registered_image;
            
            % Normalize the padded images
            target_norm = double(padded_target) / double(max(padded_target(:)));
            registered_norm = double(padded_registered) / double(max(padded_registered(:)));
            
            % Create the 4D RGB overlay volume
            overlay_volume = zeros([max_size, 3]); % Create RGB overlay
            overlay_volume(:,:,:,1) = target_norm;       % Red channel for target
            overlay_volume(:,:,:,2) = registered_norm;  % Green channel for registered source
            overlay_volume(:,:,:,3) = 0;                % Blue channel (unused)
            
            % Display the 3D overlay using volshow
            % figure('Name', '3D Fused Volume Viewer', 'NumberTitle', 'off');
            volshow(overlay_volume, 'Colormap', jet(256), 'Alphamap', linspace(0,1,256));

            fused_image = imfuse(max(target_image,[],3), max(registered_image,[],3), 'falsecolor','Scaling','joint','ColorChannels',[1 2 0]);
            % Create a new figure window for the fused image
            figure('Name', 'Fused Image', 'NumberTitle', 'off');
            imshow(fused_image)
            title('Overlay of Target and Registered Source Z- Projections');
        end
    end

    function togglePointSelection(hf_main, src)
        hf_main.UserData.isSelectingPoints = src.Value;
        if hf_main.UserData.isSelectingPoints
            disp('Point selection enabled. Click on the source image first, then on the target image.');
             % -----------------------------------------------------
            % If "Delete Points" mode is currently ON, turn it OFF
            % -----------------------------------------------------
            if hf_main.UserData.isDeletingPoints
                hf_main.UserData.isDeletingPoints = false;
                disp('Delete Points mode disabled because Point Selection was toggled on.');
                
                % Untoggle the Delete Points pushbutton
                set(findobj(hf_main.UserData.hf_controls, 'String', 'Delete Fiducial Point Pair'), 'Value', 0);
    
                % Remove any delete callbacks from the images
                set(hf_main.UserData.hImgSource, 'ButtonDownFcn', '');
                set(hf_main.UserData.hImgTarget, 'ButtonDownFcn', '');
            end
            % Set up callbacks for images
            set(hf_main.UserData.hImgSource, 'ButtonDownFcn', @(src, event) selectPoint(src, event, hf_main, 'source'));
            set(hf_main.UserData.hImgTarget, 'ButtonDownFcn', @(src, event) selectPoint(src, event, hf_main, 'target'));
        else
            disp('Point selection disabled.');
            % Remove callbacks
            set(hf_main.UserData.hImgSource, 'ButtonDownFcn', '');
            set(hf_main.UserData.hImgTarget, 'ButtonDownFcn', '');
        end
    end

    function selectPoint(src, ~, hf_main, imageType)
        if ~hf_main.UserData.isSelectingPoints
            return;
        end
    
            % Get the axes
            ax = ancestor(src, 'axes');
        
            % Get the current point in the axes
            clickPos = get(ax, 'CurrentPoint');
            x = clickPos(1,1);
            y = clickPos(1,2);
    
        if ~isfield(hf_main.UserData, 'nextSelection') || isempty(hf_main.UserData.nextSelection)
            hf_main.UserData.nextSelection = 'source';
        end
    
        if strcmp(hf_main.UserData.nextSelection, imageType)
            if strcmp(imageType, 'source')
                % Store the selected source point
                hf_main.UserData.currentsourcePoint = [x, y, hf_main.UserData.source_z];
    
                % Generate a random color for this point pair
                randColor = rand(1,3);
    
                % Plot the source point immediately
                axes(hf_main.UserData.ha_source);
                hold on;
                hsourceMarker = plot(x, y, '.', 'Color', randColor, 'MarkerSize', 12, 'LineWidth', 2);
                hold off;
    
                % Store the source marker and color temporarily
                hf_main.UserData.currentRandColor = randColor;
                hf_main.UserData.currentsourceMarker = hsourceMarker;
    
                hf_main.UserData.nextSelection = 'target';
                disp('source point selected. Now select the corresponding point in the target image.');
            else
                % Store the selected target point
                hf_main.UserData.currenttargetPoint = [x, y, hf_main.UserData.target_z];
    
                % Plot the target point
                axes(hf_main.UserData.ha_target);
                hold on;
                htargetMarker = plot(x, y, '.', 'Color', hf_main.UserData.currentRandColor, 'MarkerSize', 12, 'LineWidth', 2);
                hold off;
    
                % Store the target marker
                hf_main.UserData.currenttargetMarker = htargetMarker;
    
                % Store the point pair
                storePointPair(hf_main);
                hf_main.UserData.nextSelection = 'source';
            end
        else
            disp(['Invalid selection. Please select a point in the ', hf_main.UserData.nextSelection, ' image next.']);
        end
    end

    function storePointPair(hf_main)
        % Ensure the fields exist
        if ~isfield(hf_main.UserData, 'sourcePoints')
            hf_main.UserData.sourcePoints = [];
            hf_main.UserData.targetPoints = [];
            hf_main.UserData.pointColors = [];
            hf_main.UserData.sourceMarkers = [];
            hf_main.UserData.targetMarkers = [];
        end
    
        % 1) Append the new points/markers to arrays
        hf_main.UserData.sourcePoints(end+1, :) = hf_main.UserData.currentsourcePoint;
        hf_main.UserData.targetPoints(end+1, :) = hf_main.UserData.currenttargetPoint;
        hf_main.UserData.pointColors(end+1, :) = hf_main.UserData.currentRandColor;
    
        hf_main.UserData.sourceMarkers(end+1) = hf_main.UserData.currentsourceMarker;
        hf_main.UserData.targetMarkers(end+1) = hf_main.UserData.currenttargetMarker;
    
        % 2) Now find the new point index (it’s the last row in sourcePoints)
        iPt = size(hf_main.UserData.sourcePoints,1);
    
        % 3) Make each marker clickable:
        set(hf_main.UserData.sourceMarkers(iPt), ...
            'HitTest','on', ...
            'PickableParts','all', ...
            'UserData', struct('pointIndex', iPt, 'type','source'), ...
            'ButtonDownFcn', @(marker, evt) markerClicked(marker, evt, hf_main));
    
        set(hf_main.UserData.targetMarkers(iPt), ...
            'HitTest','on', ...
            'PickableParts','all', ...
            'UserData', struct('pointIndex', iPt, 'type','target'), ...
            'ButtonDownFcn', @(marker, evt) markerClicked(marker, evt, hf_main));
    
        % 4) Clear temporary variables
        hf_main.UserData.currentsourcePoint = [];
        hf_main.UserData.currenttargetPoint = [];
        hf_main.UserData.currentRandColor   = [];
        hf_main.UserData.currentsourceMarker = [];
        hf_main.UserData.currenttargetMarker = [];
    end

    function toggleDeletePoints(hf_main, src)
        hf_main.UserData.isDeletingPoints = src.Value;
        if hf_main.UserData.isDeletingPoints
            disp('Delete Points mode enabled. Click **directly** on a marker to delete it.');
    
            % If point selection mode was on, turn it off
            if hf_main.UserData.isSelectingPoints
                hf_main.UserData.isSelectingPoints = false;
                % Untoggle the "Select Fiducial Points" button
                set(findobj(hf_main.UserData.hf_controls, ...
                    'String', 'Select Fiducial Points'), 'Value', 0);
                disp('Point selection turned off.');
                
                % Remove selection callbacks from the images
                set(hf_main.UserData.hImgSource, 'ButtonDownFcn', '');
                set(hf_main.UserData.hImgTarget, 'ButtonDownFcn', '');
            end
    
        else
            disp('Delete Points mode disabled.');
        end
    end

    function markerClicked(marker, ~, hf_main)
        % Only delete if we are in "delete points" mode
        if ~hf_main.UserData.isDeletingPoints
            return;
        end
    
        % Retrieve the point index that this marker represents
        if isfield(marker.UserData, 'pointIndex')
            iPoint = marker.UserData.pointIndex;
        else
            warning('Marker clicked but has no .pointIndex in UserData.');
            return;
        end
    
        % 1) Delete this marker itself
        delete(marker);
    
        % 2) Also delete the *partner* marker in the other image (same iPoint)
        if iPoint <= numel(hf_main.UserData.sourceMarkers)
            if ishghandle(hf_main.UserData.sourceMarkers(iPoint))
                delete(hf_main.UserData.sourceMarkers(iPoint));
            end
            hf_main.UserData.sourceMarkers(iPoint) = [];
        end
        if iPoint <= numel(hf_main.UserData.targetMarkers)
            if ishghandle(hf_main.UserData.targetMarkers(iPoint))
                delete(hf_main.UserData.targetMarkers(iPoint));
            end
            hf_main.UserData.targetMarkers(iPoint) = [];
        end
    
        % 3) Remove the corresponding row from sourcePoints & targetPoints
        if iPoint <= size(hf_main.UserData.sourcePoints,1)
            hf_main.UserData.sourcePoints(iPoint,:) = [];
        end
        if iPoint <= size(hf_main.UserData.targetPoints,1)
            hf_main.UserData.targetPoints(iPoint,:) = [];
        end
    
        % 4) Remove color if you store that per pair
        if iPoint <= size(hf_main.UserData.pointColors,1)
            hf_main.UserData.pointColors(iPoint,:) = [];
        end
    
        fprintf('Deleted pair index %d from sourcePoints/targetPoints.\n', iPoint);
    end

    function clearAllPoints(hf_main)
        % Delete any temporary single-click markers
        if isfield(hf_main.UserData, 'currentsourceMarker') && ~isempty(hf_main.UserData.currentsourceMarker)
            if ishghandle(hf_main.UserData.currentsourceMarker)
                delete(hf_main.UserData.currentsourceMarker);
            end
            hf_main.UserData.currentsourceMarker = [];
        end
        if isfield(hf_main.UserData, 'currenttargetMarker') && ~isempty(hf_main.UserData.currenttargetMarker)
            if ishghandle(hf_main.UserData.currenttargetMarker)
                delete(hf_main.UserData.currenttargetMarker);
            end
            hf_main.UserData.currenttargetMarker = [];
        end
        
        % Reset these fields
        hf_main.UserData.currentsourcePoint = [];
        hf_main.UserData.currenttargetPoint = [];
        hf_main.UserData.currentRandColor   = [];
        hf_main.UserData.nextSelection      = 'source';
        
        %-------------------------------------------
        % Now safely delete all stored point markers
        %-------------------------------------------
        if isfield(hf_main.UserData, 'sourcePoints') && ~isempty(hf_main.UserData.sourcePoints)
            % A) Delete source markers
            validS = ishghandle(hf_main.UserData.sourceMarkers);
            delete(hf_main.UserData.sourceMarkers(validS)); % delete only valid handles
            hf_main.UserData.sourceMarkers = [];
            
            % B) Delete target markers
            validT = ishghandle(hf_main.UserData.targetMarkers);
            delete(hf_main.UserData.targetMarkers(validT));
            hf_main.UserData.targetMarkers = [];
            
            % Finally, clear the underlying data
            hf_main.UserData.sourcePoints  = [];
            hf_main.UserData.targetPoints  = [];
            hf_main.UserData.pointColors   = [];
            
            disp('Cleared all points.');
        else
            disp('No points to clear.');
        end
    end

    function saveData(hf_main)
        % Prompt user to choose file location and name
        [fileName, filePath] = uiputfile('*.mat', 'Save Data As');
        if isequal(fileName, 0) || isequal(filePath, 0)
            disp('Save canceled');
            return;
        end
    
        % Extract data to save
        target_points = hf_main.UserData.targetPoints;
        source_points = hf_main.UserData.sourcePoints;

        Transformation.A = hf_main.UserData.A;
        Transformation.b = hf_main.UserData.b;
        Transformation.C_tilde = hf_main.UserData.C_tilde;
        Transformation.method = hf_main.UserData.method;
        Transformation.points = hf_main.UserData.points;
        Transformation.lambda = hf_main.UserData.lambda;
        Transformation.sigma = hf_main.UserData.sigma;
        
        % Save the data in the specified location
        save(fullfile(filePath, fileName), 'target_points', 'source_points','Transformation');
        disp(['Data saved to ', fullfile(filePath, fileName)]);
    end

    function saveRegisteredImage(hf_main)
        % Retrieve the registered image from UserData
        registered_image = hf_main.UserData.registered_image;
        if isempty(registered_image)
            disp('No registered image to save.');
            return;
        end
    
        % Check dimensionality
        dimReg = ndims(registered_image);
    
        if dimReg == 2
            %------------------------------------------------------
            % CASE A: 2D
            %------------------------------------------------------
            % We can save as PNG, TIF, JPG, or MAT.
    
            formatList = {'PNG','TIF','JPG','MAT'};
            [ind, tf] = listdlg('ListString', formatList, ...
                'SelectionMode', 'single', ...
                'PromptString', 'Select a 2D image format to save:', ...
                'Name', 'Save 2D Registered Image', ...
                'ListSize', [200 100]);
            if ~tf
                disp('Save canceled.');
                return;
            end
            chosen = formatList{ind};
    
            switch chosen
                case 'PNG'
                    [fileName, filePath] = uiputfile('*.png','Save 2D Registered Image As (PNG)');
                    if isequal(fileName,0), disp('Save canceled'); return; end
                    outPath = fullfile(filePath, fileName);
                    imwrite(registered_image, outPath, 'png');
                    disp(['Saved 2D registered image to ', outPath]);
    
                case 'TIF'
                    [fileName, filePath] = uiputfile('*.tif','Save 2D Registered Image As (TIF)');
                    if isequal(fileName,0), disp('Save canceled'); return; end
                    outPath = fullfile(filePath, fileName);
                    imwrite(registered_image, outPath, 'tif');
                    disp(['Saved 2D registered image to ', outPath]);
    
                case 'JPG'
                    [fileName, filePath] = uiputfile({'*.jpg;*.jpeg','JPEG Image (*.jpg, *.jpeg)'}, ...
                        'Save 2D Registered Image As (JPG)');
                    if isequal(fileName,0), disp('Save canceled'); return; end
                    outPath = fullfile(filePath, fileName);
                    imwrite(registered_image, outPath, 'jpg');
                    disp(['Saved 2D registered image to ', outPath]);
    
                case 'MAT'
                    [fileName, filePath] = uiputfile('*.mat','Save 2D Registered Image As (MAT)');
                    if isequal(fileName,0), disp('Save canceled'); return; end
                    outPath = fullfile(filePath, fileName);
                    save(outPath, 'registered_image');
                    disp(['Saved 2D registered image (MAT) to ', outPath]);
            end
    
        elseif dimReg == 3
            %------------------------------------------------------
            % CASE B: 3D
            %------------------------------------------------------
            % We can save as multi-page TIF stack or MAT.
    
            formatList = {'TIF','MAT'};
            [ind, tf] = listdlg('ListString', formatList, ...
                'SelectionMode', 'single', ...
                'PromptString', 'Select a 3D image format to save:', ...
                'Name', 'Save 3D Registered Image', ...
                'ListSize', [200 70]);
            if ~tf
                disp('Save canceled.');
                return;
            end
            chosen = formatList{ind};
    
            switch chosen
                case 'TIF'
                    [fileName, filePath] = uiputfile('*.tif','Save 3D Registered Image Stack As');
                    if isequal(fileName,0), disp('Save canceled'); return; end
                    outPath = fullfile(filePath, fileName);
    
                    % Write multi-page TIF stack
                    numSlices = size(registered_image, 3);
                    for s = 1:numSlices
                        if s == 1
                            imwrite(registered_image(:,:,s), outPath, ...
                                    'tif', 'WriteMode','overwrite');
                        else
                            imwrite(registered_image(:,:,s), outPath, ...
                                    'tif', 'WriteMode','append');
                        end
                    end
                    disp(['Saved 3D TIF stack (', num2str(numSlices), ...
                          ' slices) to ', outPath]);
    
                case 'MAT'
                    [fileName, filePath] = uiputfile('*.mat','Save 3D Registered Image As (MAT)');
                    if isequal(fileName,0), disp('Save canceled'); return; end
                    outPath = fullfile(filePath, fileName);
                    save(outPath, 'registered_image');
                    disp(['Saved 3D registered image (MAT) to ', outPath]);
            end
    
        else
            % If you ever have more than 3D or something else
            warning('Registered image dimension = %d is not handled.', dimReg);
        end
    end



end