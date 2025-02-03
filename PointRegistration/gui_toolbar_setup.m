function gui_toolbar_setup(hf, ha_source, ha_target, ha_combined)
    tb = uitoolbar(hf);
    
    % Rotate tool
    uitoggletool(tb, 'TooltipString', 'Rotate 3D', ...
        'ClickedCallback', @(~,~) activateTool(@rotate3d, ha_source, ha_target, ha_combined));
    
    % Zoom tool
    uitoggletool(tb, 'TooltipString', 'Zoom', ...
        'ClickedCallback', @(~,~) activateTool(@zoom, ha_source, ha_target, ha_combined));
    
    % Pan tool
    uitoggletool(tb, 'TooltipString', 'Pan', ...
        'ClickedCallback', @(~,~) activateTool(@pan, ha_source, ha_target, ha_combined));
end

% Activate selected tool for all axes
function activateTool(toolFunc, ha1, ha2, ha3)
    rotate3d off; zoom off; pan off;
    toolFunc(ha1); toolFunc(ha2); toolFunc(ha3);
end