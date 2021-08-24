function [blade_corners] = getSpatulaBlade(markers_trajectories, nFrames, bladeCloseCorner, bladeLCloseCorner, bladeRfarCorner,bladeLfarCorner)

% frame (i.e. coordinate system) in the spatula beam that is connected to the blade:

% frame origin:
frame_spat.origin = markers_trajectories.sR;

% frame x,y,z axes:
% x
frame_spat.x = markers_trajectories.sUp - markers_trajectories.sR; % vector from red marker to darkBlue marker, so x = darkBlue - red
frame_spat.x = frame_spat.x./repmat(vecnorm(frame_spat.x,2,2),1,3); % unit vector now

frame_spat.y = [];  % just to have the struct fields in the order x,y,z

% z
tmp_vector = markers_trajectories.sClose - markers_trajectories.sR; % vector from red marker to green marker, so x = green - red
tmp_vector = tmp_vector./repmat(vecnorm(tmp_vector,2,2),1,3); % unit vector now
frame_spat.z = cross(frame_spat.x,tmp_vector); % because we want z to be normal to the plane of the 3 markers, it is the cross product between x and (green - red) vectors
frame_spat.z = frame_spat.z./repmat(vecnorm(frame_spat.z,2,2),1,3); % unit vector now

% y
frame_spat.y = cross(frame_spat.z, frame_spat.x); % because x and y must be normal, we can't use the vector (green - red), but another vector in the same plane as x and (green - red) that is normal to x
frame_spat.y = frame_spat.y./repmat(vecnorm(frame_spat.y,2,2),1,3); % unit vector now

clearvars tmp_vector


transf_mtx_LOC_glob = zeros(4,4,nFrames);

blade_corners.Rclose = zeros(nFrames,4);
blade_corners.Lclose = zeros(nFrames,4);
blade_corners.Rfar = zeros(nFrames,4);
blade_corners.Lfar = zeros(nFrames,4);
for f=1:nFrames
    transf_mtx_LOC_glob(:,:,f) = [frame_spat.x(f,:)' frame_spat.y(f,:)' frame_spat.z(f,:)' frame_spat.origin(f,:)';...
                                       0                  0                  0                  1              ];
    blade_corners.Rclose(f,:) = (transf_mtx_LOC_glob(:,:,f) * bladeCloseCorner.local)';
    blade_corners.Lclose(f,:) = (transf_mtx_LOC_glob(:,:,f) * bladeLCloseCorner)';
    blade_corners.Rfar(f,:) = (transf_mtx_LOC_glob(:,:,f) * bladeRfarCorner.local)';
    blade_corners.Lfar(f,:) = (transf_mtx_LOC_glob(:,:,f) * bladeLfarCorner.local)';
end


blade_corners.Rclose = blade_corners.Rclose(:,1:3);
blade_corners.Lclose = blade_corners.Lclose(:,1:3);
blade_corners.Rfar = blade_corners.Rfar(:,1:3);
blade_corners.Lfar = blade_corners.Lfar(:,1:3);





end