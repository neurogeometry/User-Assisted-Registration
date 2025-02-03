function Registration_GUI()
    % Main GUI figure (make it non-resizable)
    hf = figure('Name', 'Registration Selector', ...
                'MenuBar', 'none', ...
                'NumberTitle', 'off', ...
                'Resize', 'off', ... 
                'Position', [500, 500, 300, 200]);

    fontSize=10;

    % Instructions
    h_viewpanel = uipanel('Parent', hf, 'FontSize', fontSize, ...
                          'Units','pixels','Position', [11 10, 280, 180], ...
                          'Title','Select a registration type');
    
    % Create the button group
    buttonGroup = uibuttongroup('Parent', h_viewpanel, ...
                                'Position', [0.05, 0.25, 0.9, 0.6], ...
                                'BorderType', 'none',...
                                'SelectionChangedFcn', @selectionChanged);

    % Radio buttons for registration types
    % (We capture the handle of the ImageRegistration button to set it as default)
    imageRegRadio = uicontrol('Style', 'radiobutton',  ...
                              'Parent', buttonGroup, ...
                              'Position', [40, 80, 240, 20], ...
                              'String', 'Image Registration', ...
                              'FontSize', 10, ...
                              'Tag', 'ImageRegistration');
    
    uicontrol('Style', 'radiobutton', ...
              'Parent', buttonGroup, ...
              'Position', [40, 50, 240, 20], ...
              'String', 'Trace Registration', ...
              'FontSize', 10, ...
              'Tag', 'TraceRegistration'); 
    
    uicontrol('Style', 'radiobutton', ...
              'Parent', buttonGroup, ...
              'Position', [40, 20, 240, 20], ...
              'String', 'Point Set Registration', ...
              'FontSize', 10, ...
              'Tag', 'PointRegistration');
   

    % Set the default radio button selection to ImageRegistration
    buttonGroup.SelectedObject = imageRegRadio;

    % Initialize selectedRegistration to the default
    selectedRegistration = 'ImageRegistration';

    % Continue button
    uicontrol('Style', 'pushbutton', ...
              'Position', [100, 20, 100, 30], ...
              'String', 'Continue', ...
              'FontSize', 10, ...
              'Callback', @continueCallback);

    % Callback for radio button selection
    function selectionChanged(~, event)
        selectedRegistration = event.NewValue.Tag;
    end

    % Callback for the Continue button
    function continueCallback(~, ~)
        % Check if a selection was made
        if isempty(selectedRegistration)
            errordlg('Please select a registration type before continuing.', 'Error');
            return;
        end

        % Construct the path to the selected folder
        folderPath = fullfile(pwd, selectedRegistration);

        % Check if the folder exists
        if isfolder(folderPath)
            % Add the selected folder to the MATLAB path
            addpath(folderPath);

            % Run the DataLoader.m file in the selected folder
            fullPath = fullfile(folderPath, 'DataLoader.m');
            if exist(fullPath, 'file') == 2
                run(fullPath); % Run the DataLoader.m file
            else
                errordlg(['DataLoader.m not found in ', selectedRegistration, ' folder.'], 'Error');
            end

            % Close the GUI window
            close(hf);
        else
            errordlg(['Folder not found: ', folderPath], 'Error');
        end
    end
end
