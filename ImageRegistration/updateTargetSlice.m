function updateTargetSlice(src, ~, hf_main)
    hf_main.UserData.target_z = round(get(src, 'Value'));
    set(src, 'Value', hf_main.UserData.target_z); % Ensure slider value is integer
    set(hf_main.UserData.target_z_text, 'String', ['Z = ', num2str(hf_main.UserData.target_z)]);
    % Update the displayed image data without clearing axes
    set(hf_main.UserData.hImgTarget, 'CData', hf_main.UserData.target_image(:,:,hf_main.UserData.target_z));
end