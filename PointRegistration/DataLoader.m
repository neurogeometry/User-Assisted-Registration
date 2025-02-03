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
        'String', 'Source Points:', 'FontSize', fontSize, 'HorizontalAlignment','left');

    hsource = uicontrol('Style', 'edit', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.20 0.81 0.60 0.10], ...
        'String', hf.UserData.source, 'Enable', 'on', 'FontSize', fontSize);

    uicontrol('Style', 'pushbutton', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.82 0.81 0.15 0.10], ...
        'String', 'Choose', 'FontSize', fontSize, ...
        'Callback', @(~,~) pickPointFile(hsource));

    %-----------------------------------------------------------------
    % (2) target file
    %-----------------------------------------------------------------
    uicontrol('Style', 'text', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.02 0.55 0.20 0.10], ...
        'String', 'Target Points:', 'FontSize', fontSize, 'HorizontalAlignment','left');

    htarget = uicontrol('Style', 'edit', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.20 0.56 0.60 0.10], ...
        'String', hf.UserData.target, 'Enable', 'on', 'FontSize', fontSize);

    uicontrol('Style', 'pushbutton', 'Parent', h_viewpanel, ...
        'Units', 'normalized', 'Position', [0.82 0.56 0.15 0.10], ...
        'String', 'Choose', 'FontSize', fontSize, ...
        'Callback', @(~,~) pickPointFile(htarget));

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

    function pickPointFile(hEdit)
        [file,path] = uigetfile({'*.mat;*.txt',...
           'Point Files (*.mat, *.txt)'},...
           'Select a Point File');
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
function load_data_and_close(hsource,htarget,hFid,hf)
    source_path = hsource.String;
    target_path = htarget.String;
    fid_path    = hFid.String;

    % Basic check
    if isempty(source_path) || isempty(target_path)
        errordlg('Please select both source and target paths.','Path Error');
        return;
    end

    % Build data_struct
    data_struct = struct('source_path',source_path, ...
                         'target_path',target_path);

    if ~isempty(fid_path)
        % Loaded session
        loaded = load(fid_path);
        % Must have at least 'targetPoints','sourcePoints','Transformation'
        reqFields = {'targetPoints','sourcePoints','Transformation'};
        missing = setdiff(reqFields, fieldnames(loaded));
        if ~isempty(missing)
            errordlg(['Fiducial file missing required fields: ', ...
                       strjoin(missing,', ')],'Load Error');
            return;
        end

        % Merge them in
        data_struct.targetPoints   = loaded.targetPoints;
        data_struct.sourcePoints   = loaded.sourcePoints;
        data_struct.Transformation = loaded.Transformation;

        % Now call in "loaded" mode
        gui_optimization('loaded', data_struct);

    else
        % New session
        gui_optimization('new', data_struct);
    end

    close(hf);
end
