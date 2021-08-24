%% add mocap toolboxes to searched paths
addpath(genpath('MocapRecovery-master'))


%% IMPORT MARKERS 3D POSITION 
% FROM STATIC TRIAL WITH MARKERS ON THE SPATULA BLADE

static_file = 'static_spatula_with_blade_corners.c3d';

static_trajectories = mcread(static_file);

markersName = static_trajectories.markerName;
tmp = char(markersName); 
markersName(~isnan(str2double(cellstr(tmp(:,2:end))))) = []; % remove unlabeled trajectories
clearvars tmp 

bladeCloseCorner.global.up     = static_trajectories.data(:,repelem(strcmp(markersName,'bladeCloseUp'),3));
bladeCloseCorner.global.down   = static_trajectories.data(:,repelem(strcmp(markersName,'bladeCloseDown'),3));
bladeCloseCorner.global.center = (mean(bladeCloseCorner.global.up(100:500,:)) + mean(bladeCloseCorner.global.down(100:500,:)))/2;

bladeRfarCorner.global.up     = static_trajectories.data(:,repelem(strcmp(markersName,'bladeUpR'),3));
bladeRfarCorner.global.down   = static_trajectories.data(:,repelem(strcmp(markersName,'bladeDownR'),3));
bladeRfarCorner.global.center = (mean(bladeRfarCorner.global.up(100:500,:)) + mean(bladeRfarCorner.global.down(100:500,:)))/2;

bladeLfarCorner.global.up     = static_trajectories.data(:,repelem(strcmp(markersName,'bladeUpL'),3));
bladeLfarCorner.global.down   = static_trajectories.data(:,repelem(strcmp(markersName,'bladeDownL'),3));
bladeLfarCorner.global.center = (mean(bladeLfarCorner.global.up(100:500,:)) + mean(bladeLfarCorner.global.down(100:500,:)))/2;


tmp_markersName = repelem(markersName,3);

for m=1:3:length(tmp_markersName)-4*3 % - markers on tips (up,down)
    eval(['marker.' tmp_markersName{m} ' = static_trajectories.data(100:500,m:m+2);']);
end
clearvars m tmp_markersName


%% frame (i.e. coordinate system) in the spatula beam that is connected to the blade:

% frame origin:
frame_spat.origin = mean(marker.sR);

% frame x,y,z axes:
% x
frame_spat.x = mean(marker.sUp) - mean(marker.sR); % vector from red marker to darkBlue marker, so x = darkBlue - red
frame_spat.x = frame_spat.x/norm(frame_spat.x); % unit vector now

frame_spat.y = [];  % just to have the struct fields in the order x,y,z

% z
tmp_vector = mean(marker.sClose) - mean(marker.sR); % vector from red marker to green marker, so x = green - red
tmp_vector = tmp_vector/norm(tmp_vector); % unit vector now
frame_spat.z = cross(frame_spat.x,tmp_vector); % because we want z to be normal to the plane of the 3 markers, it is the cross product between x and (green - red) vectors
frame_spat.z = frame_spat.z/norm(frame_spat.z); % unit vector now

% y
frame_spat.y = cross(frame_spat.z, frame_spat.x); % because x and y must be normal, we can't use the vector (green - red), but another vector in the same plane as x and (green - red) that is normal to x
frame_spat.y = frame_spat.y/norm(frame_spat.y); % unit vector now

clearvars tmp_vector


%% transformation matrix from Vicon global frame to the local frame_spat:

% transforamtion matrix from local to global:
transf_mtx_LOC_glob = [frame_spat.x' frame_spat.y' frame_spat.z' frame_spat.origin';...
                            0             0             0             1              ];

% transforamtion matrix from global to local:
transf_mtx_GLOB_loc = inv(transf_mtx_LOC_glob);
% the inverse matrix should be equal to the multiplication of the rotation
% matrix transposed for the translation matrix with sign inverted (see pdf
% in this folder):
rot_transp = [transf_mtx_LOC_glob(1:3,1:3).', [0;0;0];[0 0 0 1]];
transl_inv = [[eye(3,3); [0 0 0]] [-transf_mtx_LOC_glob(1:3,4);1]]; % note: eye is the identity mtx.
check1 = rot_transp * transl_inv; % check1 should be equal to transf_mtx_GLOB_loc.cell_arm 
% unless the columns are not unit-length or not normal among them (which 
% means there is an error in the calculation of the frame vectors).


%% corners of the spatula blade in the local frame_spat:

bladeCloseCorner.local = transf_mtx_LOC_glob \ [bladeCloseCorner.global.center 1]';
bladeRfarCorner.local  = transf_mtx_LOC_glob \ [bladeRfarCorner.global.center 1]';
bladeLfarCorner.local  = transf_mtx_LOC_glob \ [bladeLfarCorner.global.center 1]';

% NOTE: -----------
% transf_mtx_GLOB_loc * [bladeCloseCorner.global.center 1]'   is the same as 
% transf_mtx_LOC_glob \ [bladeCloseCorner.global.center 1]'
% -----------------

% (approx.) fourth corner of the spatula blade:
v = bladeCloseCorner.local - bladeRfarCorner.local;
bladeLCloseCorner = bladeLfarCorner.local + v; % only for visualization purposes


% CHECK:
figure, 
aa=bladeCloseCorner.global.center; 
plot3(aa(1), aa(2), aa(3),'.k','MarkerSize',24), hold on
bb=bladeRfarCorner.global.center;
plot3(bb(1), bb(2), bb(3),'.k','MarkerSize',24)
cc=bladeLfarCorner.global.center;
plot3(cc(1), cc(2), cc(3),'.k','MarkerSize',24)
dd = mean(marker.sClose);
plot3(dd(1), dd(2), dd(3),'.g','MarkerSize',24)
ee = mean(marker.sFar);
plot3(ee(1), ee(2), ee(3),'.y','MarkerSize',24)
ff = mean(marker.sR);
plot3(ff(1), ff(2), ff(3),'.r','MarkerSize',24)
gg = mean(marker.sUp);
plot3(gg(1), gg(2), gg(3),'.b','MarkerSize',24)
hh = transf_mtx_LOC_glob * bladeLCloseCorner;
plot3(hh(1), hh(2), hh(3),'.k','MarkerSize',24)

clearvars aa bb cc dd ee ff gg hh


