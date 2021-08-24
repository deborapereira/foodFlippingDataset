function [tips_position] = getTweezersTips(markers_trajectories, nFrames, tip_pos_arm_notcell, tip_pos_arm_cell)


% frame (i.e. coordinate system) in the tweezers' arm with the load cell

% frame origin:
frame_arm_cell.origin = markers_trajectories.c_far; % green

% frame x,y,z axes:
% x
frame_arm_cell.x = markers_trajectories.c_long - markers_trajectories.c_far; % vector from green marker to darkBlue marker, so x = darkBlue - green
frame_arm_cell.x = frame_arm_cell.x./repmat(vecnorm(frame_arm_cell.x,2,2),1,3); % unit vector now

frame_arm_cell.y = [];  % just to have the struct fields in the order x,y,z

% z
tmp_vector = markers_trajectories.c_short - markers_trajectories.c_far; % vector from green marker to red marker, so = red - green
tmp_vector = tmp_vector./repmat(vecnorm(tmp_vector,2,2),1,3); % unit vector now
frame_arm_cell.z = cross(frame_arm_cell.x, tmp_vector); % because we want z to be normal to the plane of the 3 markers, it is the cross product between x and (red - green) vectors
frame_arm_cell.z = frame_arm_cell.z./repmat(vecnorm(frame_arm_cell.z,2,2),1,3); % unit vector now

% y
frame_arm_cell.y = cross(frame_arm_cell.z, frame_arm_cell.x); % because x and y must be normal, we can't use the vector (red - green), but another vector in the same plane as x and (red - green) that is normal to x
frame_arm_cell.y = frame_arm_cell.y./repmat(vecnorm(frame_arm_cell.y,2,2),1,3); % unit vector now

clearvars tmp_vector


% transforamtion matrix from local to global:
transf_mtx_LOC_glob.cell_arm = zeros(4,4,nFrames);
tips_position.arm_loadcell = zeros(nFrames,4);
for f=1:nFrames
    transf_mtx_LOC_glob.cell_arm(:,:,f) = [frame_arm_cell.x(f,:)' frame_arm_cell.y(f,:)' frame_arm_cell.z(f,:)' frame_arm_cell.origin(f,:)';...
                                                    0                 0                 0                 1              ];
    tips_position.arm_loadcell(f,:) = (transf_mtx_LOC_glob.cell_arm(:,:,f) * tip_pos_arm_cell.local)';
end


tips_position.arm_loadcell = tips_position.arm_loadcell(:,1:3);




% -------------------------------------------------------------------------
% frame (i.e. coordinate system) in the tweezers' arm without the load cell

% frame origin:
frame_arm_notcell.origin = markers_trajectories.a_far; % green

% frame x,y,z axes:
% x
frame_arm_notcell.x = markers_trajectories.a_short - markers_trajectories.a_far; % vector from green marker to darkBlue marker, so x = darkBlue - green
frame_arm_notcell.x = frame_arm_notcell.x./repmat(vecnorm(frame_arm_notcell.x,2,2),1,3); % unit vector now

frame_arm_notcell.y = [];  % just to have the struct fields in the order x,y,z

% z
tmp_vector = markers_trajectories.a_long - markers_trajectories.a_far; % vector from green marker to red marker, so = red - green
tmp_vector = tmp_vector./repmat(vecnorm(tmp_vector,2,2),1,3); % unit vector now
frame_arm_notcell.z = cross(frame_arm_notcell.x, tmp_vector); % because we want z to be normal to the plane of the 3 markers, it is the cross product between x and (red - green) vectors
frame_arm_notcell.z = frame_arm_notcell.z./repmat(vecnorm(frame_arm_notcell.z,2,2),1,3); % unit vector now

% y
frame_arm_notcell.y = cross(frame_arm_notcell.z, frame_arm_notcell.x); % because x and y must be normal, we can't use the vector (red - green), but another vector in the same plane as x and (red - green) that is normal to x
frame_arm_notcell.y = frame_arm_notcell.y./repmat(vecnorm(frame_arm_notcell.y,2,2),1,3); % unit vector now

clearvars tmp_vector


% transforamtion matrix from local to global:
transf_mtx_LOC_glob.notcell_arm = zeros(4,4,nFrames);
tips_position.arm_no_loadcell = zeros(nFrames,4);
for f=1:nFrames
    transf_mtx_LOC_glob.notcell_arm(:,:,f) = [frame_arm_notcell.x(f,:)' frame_arm_notcell.y(f,:)' frame_arm_notcell.z(f,:)' frame_arm_notcell.origin(f,:)';...
                                                    0                 0                 0                 1              ];
    tips_position.arm_no_loadcell(f,:) = (transf_mtx_LOC_glob.notcell_arm(:,:,f) * tip_pos_arm_notcell.local)';
end


tips_position.arm_no_loadcell = tips_position.arm_no_loadcell(:,1:3);



end







