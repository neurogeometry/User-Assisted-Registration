function hf = gui_allignment_defineframe_image()
    % Create main figure
    hf = figure('Name', 'Image Registration', 'NumberTitle', 'off', 'MenuBar', 'none');

    % Set figure position and size (optional)
    hf.Position = [100, 100, 1200, 600];

    % Create axes for Source and Target images
    ha_Source = axes('Parent', hf, 'Units', 'normalized', 'Position', [0.05, 0.1, 0.4, 0.8]);
    ha_Target = axes('Parent', hf, 'Units', 'normalized', 'Position', [0.55, 0.1, 0.4, 0.8]);

    % Create control panel
    control_panel = uipanel('Parent', hf, 'Units', 'normalized', 'Position', [0, 0, 1, 0.1], 'Title', 'Controls');

    % Store handles in UserData
    hf.UserData.ha_Source = ha_Source;
    hf.UserData.ha_Target = ha_Target;
    hf.UserData.control_panel = control_panel;
end