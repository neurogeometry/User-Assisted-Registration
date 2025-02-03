function selectPoint(src, event, r, hf, traceType)
    if hf.UserData.isDeletingPoints
        % Handle point deletion
        % For deletion, we will use a separate function
        return;
    elseif hf.UserData.isSelectingPoints
        % Get clicked position in 3D and reorder columns of r if necessary
        clickPos = event.IntersectionPoint;
        r = r(:, [2, 1, 3]);
    
        % Calculate distances from clickPos to all vertices and find nearest vertex
        distances = sqrt(sum((r - clickPos) .^ 2, 2));
        [~, closestIdx] = min(distances);
        selectedVertex = r(closestIdx, :);
    
        % Initialize matrices if they don't exist
        if ~isfield(hf.UserData, 'targetPoints')
            hf.UserData.targetPoints = [];  % Matrix to store target points
            hf.UserData.sourcePoints = [];  % Matrix to store source points
            hf.UserData.selectedPoints = {}; % Cell array for storing all selected points with markers and lines
        end
        if ~isfield(hf.UserData, 'sourcePointIndices')
            hf.UserData.sourcePointIndices = [];  % Array to store indices of selected source points
        end
    
        % Enforce source-first selection rule
        if ~isfield(hf.UserData, 'nextSelection') || isempty(hf.UserData.nextSelection)
            hf.UserData.nextSelection = 'source';  % Default to require source as first selection
        end
    
        % Hold the axes to retain existing content
        hold(hf.UserData.ha_combined, 'on');
    
        % Check if the selection follows the required order
        if strcmp(hf.UserData.nextSelection, 'source') && strcmp(traceType, 'source')

            pairIndex = length(hf.UserData.selectedPoints) + 1;
            %------------------------------------------------------------
            % 1) User selects Source point first
            %------------------------------------------------------------
            hf.UserData.currentSourcePoint = selectedVertex;
            hf.UserData.sourceMarker = plot3(hf.UserData.ha_combined, ...
                selectedVertex(1), selectedVertex(2), selectedVertex(3), ...
                'k.', 'MarkerSize', 24, 'Tag', 'FiducialMarker', ...
                'UserData', pairIndex, ...
                'HitTest','off', 'PickableParts','all', 'LineWidth', 1.5);

            % Append to source points matrix
            hf.UserData.sourcePoints = [hf.UserData.sourcePoints; selectedVertex];

            % Store the index of the selected source point
            hf.UserData.sourcePointIndices = [hf.UserData.sourcePointIndices; closestIdx];

            % Next, require a target selection
            hf.UserData.nextSelection = 'target';

        elseif strcmp(hf.UserData.nextSelection, 'target') && strcmp(traceType, 'target')

            pairIndex = length(hf.UserData.selectedPoints) + 1;
            %------------------------------------------------------------
            % 2) Then user selects Target point
            %------------------------------------------------------------
            hf.UserData.currentTargetPoint = selectedVertex;
            hf.UserData.targetMarker = plot3(hf.UserData.ha_combined, ...
                selectedVertex(1), selectedVertex(2), selectedVertex(3), ...
                'k.', 'MarkerSize', 24, 'Tag', 'FiducialMarker', ...
                'UserData', pairIndex, ...
                'HitTest','off', 'PickableParts','all', 'LineWidth', 1.5);

            % Append to target points matrix
            hf.UserData.targetPoints = [hf.UserData.targetPoints; selectedVertex];

            % Draw dashed line between the last source and this target
            sourcePoint = hf.UserData.currentSourcePoint;
            hf.UserData.lineHandle = line(hf.UserData.ha_combined, ...
                [sourcePoint(1), selectedVertex(1)], ...
                [sourcePoint(2), selectedVertex(2)], ...
                [sourcePoint(3), selectedVertex(3)], ...
                'Color', [0, 0, 0], 'LineStyle', '--', 'LineWidth', 1.5, 'Tag', 'FiducialLine', ...
                'UserData', pairIndex, ...
                'HitTest','off', 'PickableParts','none');

            %------------------------------------------------------------
            % Store markers and line in selectedPoints array for
            % undo/clear functionality
            %------------------------------------------------------------
            hf.UserData.selectedPoints{pairIndex} = struct(...
                'sourceMarker', hf.UserData.sourceMarker, ...
                'targetMarker', hf.UserData.targetMarker, ...
                'line', hf.UserData.lineHandle);

            % Reset for the next pair, requiring the next selection to be source again
            hf.UserData = rmfield(hf.UserData, ...
                {'currentTargetPoint','currentSourcePoint','targetMarker','sourceMarker','lineHandle'});
            hf.UserData.nextSelection = 'source';

        else
            %------------------------------------------------------------
            % Invalid selection order
            %------------------------------------------------------------
            disp(['Invalid selection. You must select a ', hf.UserData.nextSelection, ' point next.']);
        end
    
        % Release the hold on axes
        hold(hf.UserData.ha_combined, 'off');
    
        % Display current state of points
        % disp('Current Source Points:');
        % disp(hf.UserData.sourcePoints);
        % disp('Current Target Points:');
        % disp(hf.UserData.targetPoints);
    
        % Safely display sourcePointIndices if it exists
        % if isfield(hf.UserData, 'sourcePointIndices')
        %     disp('Current Source Point Indices:');
        %     disp(hf.UserData.sourcePointIndices);
        % end
    else
        % Neither selecting nor deleting points, do nothing
        return;
    end
end
