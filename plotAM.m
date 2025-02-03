function h = plotAM(AM, r, col, hf, traceType)
    % PLOTAM plots either points (if AM is empty) or lines based on the adjacency matrix.
    % Works with Nx2 or Nx3 data 'r' without forcing 2D to become 3D.

    % If 'col' is empty, define a default color, e.g., red.
    if ~exist('col','var') || isempty(col)
        col = [1, 0, 0];  % default to red
    end

    % Determine dimension: 2 => 2D, 3 => 3D
    dim = size(r, 2);
    if dim < 2 || dim > 3
        error('plotAM: "r" must be Nx2 or Nx3.');
    end

    % -----------------------------------------------------------------
    % 1) If the adjacency matrix is empty or all zeros, just plot points
    % -----------------------------------------------------------------
    if isempty(AM) || ~any(AM(:))
        if dim == 2
            % 2D points
            h = plot(r(:,1), r(:,2), 'o', ...
                     'Color', col, 'MarkerFaceColor', col, ...
                     'LineWidth', 1);
        else
            % 3D points
            h = plot3(r(:,1), r(:,2), r(:,3), 'o', ...
                      'Color', col, 'MarkerFaceColor', col, ...
                      'LineWidth', 1);
        end

        % Make them clickable:
        set(h, 'ButtonDownFcn', @(src,evt) selectPoint(src, evt, r, hf, traceType), ...
               'PickableParts','all', 'HitTest','on');
        return;  
    end

    % -----------------------------------------------------------
    % 2) Otherwise, use adjacency‑matrix logic to draw lines
    % -----------------------------------------------------------
    % Make AM symmetric and only keep the upper triangle
    AM = max(AM, AM');
    AM = triu(AM);

    % Extract unique labels (if your AM uses labeled edges)
    Labels = unique(full(AM(AM(:) > 0)));
    L = numel(Labels);

    % Build color array
    if size(col,1) == 1
        % A single color was given → replicate for all line sets
        cc = repmat(col, L, 1);
    else
        % 'col' might be an array of colors, one per label
        cc = col;
    end

    % Create an hggroup so we can group all lines into one handle
    h = hggroup;

    % Loop over each label
    for f = 1:L
        [i, j] = find(AM == Labels(f));  % all edges with that label
        for idx = 1:numel(i)
            % The original code flips X↔Y in the line(...) call:
            %   line(Y, X, Z, ...)
            % We'll preserve that flipping to "not alter anything."
            X = [r(i(idx),1); r(j(idx),1)];
            Y = [r(i(idx),2); r(j(idx),2)];
            if dim == 3
                Z = [r(i(idx),3); r(j(idx),3)];
                % Plot each line segment
                h_line = line(Y, X, Z, ...
                    'Color', cc(f,:), 'LineWidth', 1, ...
                    'Parent', h);
            else
                % 2D lines
                h_line = line(Y, X, ...
                    'Color', cc(f,:), 'LineWidth', 1, ...
                    'Parent', h);
            end

            % If there's a special click function:
            h_line.ButtonDownFcn = @(src, event) ...
                selectPoint(src, event, r, hf, traceType);
        end
    end
end