function updateSourceSlice(src, ~, hf_main)
    hf_main.UserData.source_z = round(get(src, 'Value'));
    set(src, 'Value', hf_main.UserData.source_z); % Ensure slider value is integer
    set(hf_main.UserData.source_z_text, 'String', ['Z = ', num2str(hf_main.UserData.source_z)]);
    % Update the displayed image data without clearing axes
    set(hf_main.UserData.hImgSource, 'CData', hf_main.UserData.source_image(:,:,hf_main.UserData.source_z));
end