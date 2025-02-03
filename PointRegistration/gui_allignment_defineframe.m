function hf = gui_allignment_defineframe()
    hf = figure('Name', 'Alignment GUI', ...
                'NumberTitle', 'off', 'MenuBar', 'none', ...
                'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);

    % Axes for source image
    ha_source = axes('Parent', hf, 'Units', 'normalized', 'Position', [0.05, 0.55, 0.4, 0.4]);
    title(ha_source, 'Source');

    % Axes for target image
    ha_target = axes('Parent', hf, 'Units', 'normalized', 'Position', [0.55, 0.55, 0.4, 0.4]);
    title(ha_target, 'Target');

    % Axes for combined trace display
    ha_combined = axes('Parent', hf, 'Units', 'normalized', 'Position', [0.55, 0.05, 0.4, 0.4]);
    title(ha_combined, 'Source Point Sets (Orange) & Target Point Sets (Teal)');
    
    % Panel for controls
    control_panel = uipanel('Parent', hf, 'Title', 'Controls', 'Units', 'normalized', ...
                            'Position', [0.05, 0.05, 0.4, 0.4]);

    hf.UserData.ha_source = ha_source;
    hf.UserData.ha_target = ha_target;
    hf.UserData.ha_combined = ha_combined;
    hf.UserData.control_panel = control_panel;
end