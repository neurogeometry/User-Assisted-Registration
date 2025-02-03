function selectPoint(src, event, r, hf, traceType)
    % Decide if we’re dealing with 2D or 3D
    dim = size(r,2);   % 2 => 2D, 3 => 3D

    if hf.UserData.isDeletingPoints
        % Handle point deletion (not shown here)
        return;

    elseif hf.UserData.isSelectingPoints
        % 1) Get the clicked position from the IntersectionPoint
        clickPos3D = event.IntersectionPoint;  % always 1x3
        % Keep only the first 'dim' components
        % e.g. if dim=2, clickPos = [X, Y], ignoring Z
        clickPos = clickPos3D(1:dim);

        % 2) Find the nearest vertex in r to that click position
        %    Both 'r' and 'clickPos' have 'dim' columns now
        distances = sqrt(sum((r - clickPos).^2, 2));
        [~, closestIdx] = min(distances);
        selectedVertex = r(closestIdx, :);

        % 3) Initialize fields if not present
        if ~isfield(hf.UserData, 'sourcePoints')
            hf.UserData.sourcePoints = [];
            hf.UserData.targetPoints = [];
            hf.UserData.selectedPoints = {};
        end
        if ~isfield(hf.UserData, 'sourcePointIndices')
            hf.UserData.sourcePointIndices = [];
        end

        % 4) Default: source-first selection rule
        if ~isfield(hf.UserData, 'nextSelection') || isempty(hf.UserData.nextSelection)
            hf.UserData.nextSelection = 'source';
        end

        hold(hf.UserData.ha_combined, 'on');

        if strcmp(hf.UserData.nextSelection, 'source') && strcmp(traceType, 'source')

            pairIndex = length(hf.UserData.selectedPoints) + 1;
            % ------------------ Selecting a source Point ------------------
            hf.UserData.currentsourcePoint = selectedVertex;

            % Plot the selected source point
            if dim == 2
                % 2D
                hf.UserData.sourceMarker = plot(hf.UserData.ha_combined, ...
                    selectedVertex(1), selectedVertex(2), ...
                    'k.', 'MarkerSize', 24, 'Tag', 'FiducialMarker', ...
                    'UserData', pairIndex, ...
                    'HitTest','off', 'PickableParts','all', 'LineWidth', 1.5);
            else
                % 3D
                hf.UserData.sourceMarker = plot3(hf.UserData.ha_combined, ...
                    selectedVertex(1), selectedVertex(2), selectedVertex(3), ...
                    'k.', 'MarkerSize', 24, 'Tag', 'FiducialMarker', ...
                    'UserData', pairIndex, ...
                    'HitTest','off', 'PickableParts','all', 'LineWidth', 1.5);
            end

            % Append to sourcePoints
            hf.UserData.sourcePoints = [hf.UserData.sourcePoints; selectedVertex];
            hf.UserData.sourcePointIndices = [hf.UserData.sourcePointIndices; closestIdx];
            
            hf.UserData.nextSelection = 'target';

        elseif strcmp(hf.UserData.nextSelection, 'target') && strcmp(traceType, 'target')

            pairIndex = length(hf.UserData.selectedPoints) + 1;
            % ------------------ Selecting a target Point ------------------
            hf.UserData.currenttargetPoint = selectedVertex;

            % Plot the selected target point
            if dim == 2
                hf.UserData.targetMarker = plot(hf.UserData.ha_combined, ...
                    selectedVertex(1), selectedVertex(2), ...
                    'k.', 'MarkerSize', 24, 'Tag', 'FiducialMarker', ...
                    'UserData', pairIndex, ...
                    'HitTest','off', 'PickableParts','all', 'LineWidth', 1.5);
            else
                hf.UserData.targetMarker = plot3(hf.UserData.ha_combined, ...
                    selectedVertex(1), selectedVertex(2), selectedVertex(3), ...
                    'k.', 'MarkerSize', 24, 'Tag', 'FiducialMarker', ...
                    'UserData', pairIndex, ...
                    'HitTest','off', 'PickableParts','all', 'LineWidth', 1.5);
            end

            % Append to targetPoints
            hf.UserData.targetPoints = [hf.UserData.targetPoints; selectedVertex];
            

            % Draw dashed line connecting the newly selected source & target
            sourcePoint = hf.UserData.currentsourcePoint;
            if dim == 2
                hf.UserData.lineHandle = line(hf.UserData.ha_combined, ...
                    [sourcePoint(1), selectedVertex(1)], ...
                    [sourcePoint(2), selectedVertex(2)], ...
                    'Color', [0,0,0], 'LineStyle','--', 'LineWidth',1.5, 'Tag', 'FiducialLine', ...
                    'UserData', pairIndex, ...
                    'HitTest','off', 'PickableParts','none');
            else
                hf.UserData.lineHandle = line(hf.UserData.ha_combined, ...
                    [sourcePoint(1), selectedVertex(1)], ...
                    [sourcePoint(2), selectedVertex(2)], ...
                    [sourcePoint(3), selectedVertex(3)], ...
                    'Color', [0,0,0], 'LineStyle','--', 'LineWidth',1.5, 'Tag', 'FiducialLine', ...
                    'UserData', pairIndex, ...
                    'HitTest','off', 'PickableParts','none');
            end

            % Store in selectedPoints array
            hf.UserData.selectedPoints{end+1} = struct( ...
                'sourceMarker', hf.UserData.sourceMarker, ...
                'targetMarker', hf.UserData.targetMarker, ...
                'line',         hf.UserData.lineHandle);

            % Reset for next pair
            hf.UserData = rmfield(hf.UserData, ...
                {'currentsourcePoint','currenttargetPoint','sourceMarker','targetMarker','lineHandle'});
            hf.UserData.nextSelection = 'source';

        else
            % Wrong order
            disp(['Invalid selection. You must select a ', hf.UserData.nextSelection, ' point next.']);
        end

        hold(hf.UserData.ha_combined,'off');

        % % Debug prints
        % disp('Current source Points:');
        % disp(hf.UserData.sourcePoints);
        % disp('Current target Points:');
        % disp(hf.UserData.targetPoints);
        % 
        % if isfield(hf.UserData, 'sourcePointIndices')
        %     disp('Current target Point Indices:');
        %     disp(hf.UserData.sourcePointIndices);
        % end

    else
        % Not selecting or deleting
        return;
    end
end