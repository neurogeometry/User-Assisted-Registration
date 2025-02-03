function markerClickCallback(src, event, hf)
    index = src.UserData;
    if hf.UserData.isDeletingPoints
        % Delete the selected point
        % Remove the markers and line
        delete(hf.UserData.selectedPoints{index}.targetMarker);
        delete(hf.UserData.selectedPoints{index}.sourceMarker);
        delete(hf.UserData.selectedPoints{index}.line);
        % Remove from selectedPoints
        hf.UserData.selectedPoints(index) = [];
        % Remove from targetPoints, sourcePoints, sourcePointIndices
        hf.UserData.targetPoints(index, :) = [];
        hf.UserData.sourcePoints(index, :) = [];
        hf.UserData.sourcePointIndices(index) = [];
        disp(['Deleted point pair at index ', num2str(index)]);
        % Update indices
        updateMarkerIndices(hf);
    else
        disp('No action taken. Activate Delete Points mode to delete points.');
    end
end