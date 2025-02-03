function DataLoader()
    % Initialize paths as empty
    source_pth = '';  
    target_pth = '';
    fiducial_pth = '';  % optional saved session

    % GUI dimensions and position
    temp = get(0);
    fi.W = 600;
    fi.H = 265;
    fi.L = temp.ScreenSize(3)/2 - fi.W/2;
    fi.B = temp.ScreenSize(4)/2 - fi.H/2;

    % Create main figure (Data Loader)
    hf = figure('Name','Data Loader','NumberTitle','off','MenuBar','none','Resize','off');
    hf.Position = [fi.L, fi.B, fi.W, fi.H];

    fontSize = 10; 

    % Panel for path selection
    h_viewpanel = uipanel('Parent', hf, 'FontSize', fontSize, ...
                          'Units','pixels','Position',[10 10 580 250], ...
                          'Title','Paths');
    
    % Initialize UserData to store paths
    hf.UserData.source    = source_pth;
    hf.UserData.target    = target_pth;
    hf.UserData.Fiducials = fiducial_pth; 

    %-----------------------------------------------------------------
    % (1) source file
    %-----------------------------------------------------------------
    uicontrol('Style', 'text', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.02 0.80 0.20 0.10], ...
        'String', 'Source Trace:', 'FontSize', fontSize, 'HorizontalAlignment','left');

    hsource = uicontrol('Style', 'edit', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.20 0.81 0.60 0.10], ...
        'String', hf.UserData.source, 'Enable', 'on', 'FontSize', fontSize);

    uicontrol('Style', 'pushbutton', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.82 0.81 0.15 0.10], ...
        'String', 'Choose', 'FontSize', fontSize, ...
        'Callback', @(~,~) pickTraceFile(hsource));

    %-----------------------------------------------------------------
    % (2) target file
    %-----------------------------------------------------------------
    uicontrol('Style', 'text', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.02 0.55 0.20 0.10], ...
        'String', 'Target Trace:', 'FontSize', fontSize, 'HorizontalAlignment','left');

    htarget = uicontrol('Style', 'edit', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.20 0.56 0.60 0.10], ...
        'String', hf.UserData.target, 'Enable', 'on', 'FontSize', fontSize);

    uicontrol('Style', 'pushbutton', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.82 0.56 0.15 0.10], ...
        'String', 'Choose', 'FontSize', fontSize, ...
        'Callback', @(~,~) pickTraceFile(htarget));

    %-----------------------------------------------------------------
    % (3) Fiducials (optional)
    %-----------------------------------------------------------------
    uicontrol('Style', 'text', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.02 0.29 0.20 0.15], ... 
        'String', 'Fiducial Points (optional):', ...
        'FontSize', fontSize, 'HorizontalAlignment','left');

    hfid = uicontrol('Style', 'edit', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.20 0.31 0.60 0.10], ...
        'String', hf.UserData.Fiducials, 'Enable', 'on', 'FontSize', fontSize);

    uicontrol('Style', 'pushbutton', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.82 0.31 0.15 0.10], ...
        'String', 'Choose', 'FontSize', fontSize, ...
        'Callback', @(~,~) pickMatFile(hfid));

    %-----------------------------------------------------------------
    % (4) Load Data Button
    %-----------------------------------------------------------------
    uicontrol('Style', 'pushbutton', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.40 0.07 0.20 0.10], ...
        'String', 'Load Data', 'FontSize', fontSize, ...
        'Callback', @(~, ~) load_data_and_close(hsource, htarget, hfid, hf));

    %---------------------
    % Nested function
    %---------------------

    function pickTraceFile(hEdit)
        [file,path] = uigetfile({'*.mat;*.swc',...
            'Trace Files (*.mat, *.swc)'}, ...
            'Select a MAT or SWC Trace File');
        if ischar(file)
            hEdit.String = fullfile(path,file);
        end
    end

    function pickMatFile(hEdit)
        [file, path] = uigetfile({'*.mat','MAT Files (*.mat)'}, ...
                                 'Select a Fiducial Points File (optional)');
        if ischar(file)
            full_path = fullfile(path, file);
            hEdit.String = full_path;
        end
    end
end

%-----------------------------------------------------------------------
% Load Data Function (plus close the DataLoader upon success)
%-----------------------------------------------------------------------
function load_data_and_close(hsource, htarget, hFid, hf)
    source_path = hsource.String;
    target_path = htarget.String;
    fid_path    = hFid.String;

    if isempty(source_path) || isempty(target_path)
        errordlg('Please select both source and target paths.','Path Error');
        return;
    end

    % Build the data_struct
    data_struct = struct('source_path', source_path, ...
                         'target_path', target_path);

    if ~isempty(fid_path)
        % This means we have a "loaded" session
        loaded = load(fid_path);

        % Check that it has the essential fields for a loaded session
        needed = {'targetPoints','sourcePoints','Transformation'};
        missing = setdiff(needed, fieldnames(loaded));
        if ~isempty(missing)
            errordlg(['Fiducial file missing required fields: ', ...
                       strjoin(missing, ', ')],'Load Error');
            return;
        end

        % Merge them into data_struct
        % we typically store targetPoints, sourcePoints, Transformation
        data_struct.targetPoints   = loaded.targetPoints;
        data_struct.sourcePoints   = loaded.sourcePoints;
        data_struct.Transformation = loaded.Transformation;

        % Now call gui_optimization in 'loaded' mode
        gui_optimization('loaded', data_struct);
    else
        % Otherwise, treat as a "new" session
        gui_optimization('new', data_struct);
    end

    % Close the loader
    close(hf);
end
