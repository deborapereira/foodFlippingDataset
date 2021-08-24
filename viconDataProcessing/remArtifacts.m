function [markers_trajectories] = remArtifacts(markers_trajectories, marker_name, threshold)


% dist_hUpR_hDownR  --  to check the traj of hDownR and hUpR
% dist_hUpL_hUpR    --  to check the traj of hUpL
% dist_hUpL_hDownL  --  to check the traj of hDownL
% dist_hUpR_hMid    --  to check the traj of hMid 

% dist_sR_sUp     --  to check the traj of sUp and sR
% dist_sR_sClose  --  to check the traj of sClose
% dist_sR_sFar  --  to check the traj of sFar  


if strcmp(marker_name,'hDownR') || strcmp(marker_name,'hUpL') || strcmp(marker_name,'hMid')
    refMarker = 'hUpR';
elseif strcmp(marker_name,'hUpR')
    refMarker = 'hDownR';
elseif strcmp(marker_name,'hDownL')
    refMarker = 'hUpL';
    
elseif strcmp(marker_name,'sUp') || strcmp(marker_name,'sClose') || strcmp(marker_name,'sFar') 
    refMarker = 'sR';
elseif strcmp(marker_name,'sR')
    refMarker = 'sUp';
end
    


trajL = markers_trajectories.(marker_name)(1:end-1,1);
trajR = markers_trajectories.(marker_name)(2:end,1); 
right_extremities = find(isnan(trajL) & ~isnan(trajR));
left_extremities = find(isnan(trajR) & ~isnan(trajL));
left_extremities = left_extremities + 1; % because it starts in the element 2  (trajR = markers_trajectories.(marker_name)(2:end,1))



% replace the extremities of gaps with NaNs if those extremities have filter artifacts
% (i.e. sudden changes in the distance between that marker and another reference marker): 

dist = vecnorm(markers_trajectories.(refMarker) - markers_trajectories.(marker_name),2,2);

for L=1:length(left_extremities)
    % if there is an artifact:
    if abs(dist(left_extremities(L)-2)-dist(left_extremities(L)-1)) > threshold
        % check until when the artifact lasts and, for those samples, change the trajectory to NaNs:
        markers_trajectories.(marker_name)(left_extremities(L)-1,:) = NaN;
        shift = 2;
        while true
            if abs(dist(left_extremities(L)-1-shift)-dist(left_extremities(L)-shift)) > threshold
                markers_trajectories.(marker_name)(left_extremities(L)-shift,:) = NaN;
                shift = shift + 1;
            else
                break;
            end
        end
    end
end


for r=1:length(right_extremities)
    % if there is an artifact:
    if abs(dist(right_extremities(r)+2)-dist(right_extremities(r)+1)) > threshold
        % check until when the artifact lasts and, for those samples, change the trajectory to NaNs:
        markers_trajectories.(marker_name)(right_extremities(r)+1,:) = NaN;
        shift = 2;
        while true
            if abs(dist(right_extremities(r)+1+shift)-dist(right_extremities(r)+shift)) > threshold
                markers_trajectories.(marker_name)(right_extremities(r)+shift,:) = NaN;
                shift = shift + 1;
            else
                break;
            end
        end
    end
end




end