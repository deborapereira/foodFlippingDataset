%% add mocap toolboxes to searched paths
addpath(genpath('MocapRecovery-master'))


%% IMPORT MARKERS 3D POSITION 
% FROM STATIC TRIAL WITH MARKERS ON THE TWEEZER TIPS

static_file = 'static_tweezers_with_tips.c3d'; % (or) static_with_tips11.c3d

static_trajectories = mcread(static_file);

markersName = static_trajectories.markerName;
tmp = char(markersName); 
markersName(~isnan(str2double(cellstr(tmp(:,2:end))))) = []; % remove unlabeled trajectories
clearvars tmp 


%% tweezers' tips position in global (Vicon) coordinate system:

tip_pos_arm_cell.global.up     = static_trajectories.data(:,repelem(strcmp(markersName,'tip_cell_up'),3));
tip_pos_arm_cell.global.down   = static_trajectories.data(:,repelem(strcmp(markersName,'tip_cell_down'),3));
tip_pos_arm_cell.global.center = (mean(tip_pos_arm_cell.global.up) + mean(tip_pos_arm_cell.global.down))./2;

tip_pos_arm_notcell.global.up     = static_trajectories.data(:,repelem(strcmp(markersName,'tip_other_up'),3));
tip_pos_arm_notcell.global.down   = static_trajectories.data(:,repelem(strcmp(markersName,'tip_other_down'),3));
tip_pos_arm_notcell.global.center = (mean(tip_pos_arm_notcell.global.up) + mean(tip_pos_arm_notcell.global.down))./2;


%% markers position

tmp_markersName = repelem(markersName,3);

for m=1:3:length(tmp_markersName)-4*3 % - markers on tips (up,down)
    eval(['marker.' tmp_markersName{m} ' = static_trajectories.data(:,m:m+2);']);
end
clearvars m tmp_markersName

%% ========================================================================

%% frame (i.e. coordinate system) in the tweezers' arm with the load cell

% frame origin:
frame_arm_cell.origin = mean(marker.c_far); % green

% frame x,y,z axes:
% x
frame_arm_cell.x = mean(marker.c_long) - mean(marker.c_far); % vector from green marker to darkBlue marker, so x = darkBlue - green
frame_arm_cell.x = frame_arm_cell.x/norm(frame_arm_cell.x); % unit vector now

frame_arm_cell.y = [];  % just to have the struct fields in the order x,y,z

% z
tmp_vector = mean(marker.c_short) - mean(marker.c_far); % vector from green marker to red marker, so = red - green
tmp_vector = tmp_vector/norm(tmp_vector); % unit vector now
frame_arm_cell.z = cross(frame_arm_cell.x, tmp_vector); % because we want z to be normal to the plane of the 3 markers, it is the cross product between x and (red - green) vectors
frame_arm_cell.z = frame_arm_cell.z/norm(frame_arm_cell.z); % unit vector now

% y
frame_arm_cell.y = cross(frame_arm_cell.z, frame_arm_cell.x); % because x and y must be normal, we can't use the vector (red - green), but another vector in the same plane as x and (red - green) that is normal to x
frame_arm_cell.y = frame_arm_cell.y/norm(frame_arm_cell.y); % unit vector now

clearvars tmp_vector


%% transformation matrix from Vicon global frame to frame_arm_cell 

% transforamtion matrix from local to global:
transf_mtx_LOC_glob.cell_arm = [frame_arm_cell.x' frame_arm_cell.y' frame_arm_cell.z' frame_arm_cell.origin';...
                                         0                 0                 0                 1              ];

% transforamtion matrix from global to local:
transf_mtx_GLOB_loc.cell_arm = inv(transf_mtx_LOC_glob.cell_arm);
% the inverse matrix should be equal to the multiplication of the rotation
% matrix transposed for the translation matrix with sign inverted (see pdf
% in this folder):
rot_transp = [transf_mtx_LOC_glob.cell_arm(1:3,1:3).', [0;0;0];[0 0 0 1]];
transl_inv = [[eye(3,3); [0 0 0]] [-transf_mtx_LOC_glob.cell_arm(1:3,4);1]]; % note: eye is the identity mtx.
check1 = rot_transp * transl_inv; % check1 should be equal to transf_mtx_GLOB_loc.cell_arm 
% unless the columns are not unit-length or not normal among them (which 
% means there is an error in the calculation of the frame vectors).


%% respective tweezers' tip position in frame_arm_cell

tip_pos_arm_cell.local = transf_mtx_GLOB_loc.cell_arm * [tip_pos_arm_cell.global.center 1]';


% check...

aa=frame_arm_cell.origin;
figure, plot3(aa(1), aa(2), aa(3),'.','Color','#06942c','MarkerSize',24) % green
bb=mean(marker.c_short);
hold on, plot3(bb(1), bb(2), bb(3),'.r','MarkerSize',24) % red
cc=mean(marker.c_long);
plot3(cc(1), cc(2), cc(3),'.','Color','#056aad','MarkerSize',24) % dark blue
dd=tip_pos_arm_cell.global.center;
plot3(dd(1), dd(2), dd(3),'.k','MarkerSize',24) % tip
grid on

ee = aa + 40*frame_arm_cell.x;
plot3([aa(1) ee(1)],[aa(2) ee(2)],[aa(3) ee(3)],'b-') % vector x
ff = aa + 40*frame_arm_cell.y;
plot3([aa(1) ff(1)],[aa(2) ff(2)],[aa(3) ff(3)],'r-') % vector y
gg = aa + 40*frame_arm_cell.z;
plot3([aa(1) gg(1)],[aa(2) gg(2)],[aa(3) gg(3)],'g-') % vector z

plot3([aa(1) dd(1)],[aa(2) dd(2)],[aa(3) dd(3)],'k-') % vector z


% COLORS: 
% cyan:   #0fffff
% pink:   #ff13a6
% brown:  #993d00
% dark green: #06942c
% dark blue:  #056aad
% red: r

clearvars aa bb cc dd ee ff gg

%% ========================================================================

%% frame (i.e. coordinate system) in the tweezers' arm that has NOT the load cell

% frame origin:
frame_arm_notcell.origin = mean(marker.a_far); % cyan

% frame x,y,z axes:
% x
frame_arm_notcell.x = mean(marker.a_short) - mean(marker.a_far); % vector from cyan to pink marker, so x = pink - cyan
frame_arm_notcell.x = frame_arm_notcell.x/norm(frame_arm_notcell.x); % unit vector now

frame_arm_notcell.y = []; % just to have the struct fields in the order x,y,z

% z
tmp_vector = mean(marker.a_long) - mean(marker.a_far); % vector from cyan marker to brown marker, so = brown - cyan
tmp_vector = tmp_vector/norm(tmp_vector); % unit vector now
frame_arm_notcell.z = cross(frame_arm_notcell.x, tmp_vector); % because we want z to be normal to the plane of the 3 markers, it is the cross product between x and (red - green) vectors
frame_arm_notcell.z = frame_arm_notcell.z/norm(frame_arm_notcell.z); % unit vector now

% y
frame_arm_notcell.y = cross(frame_arm_notcell.z, frame_arm_notcell.x); % because x and y must be normal, we can't use the vector (red - green), but another vector in the same plane as x and (red - green) that is normal to x
frame_arm_notcell.y = frame_arm_notcell.y/norm(frame_arm_notcell.y); % unit vector now

clearvars tmp_vector


%% transformation matrix from Vicon global frame to frame_arm_notcell

transf_mtx_LOC_glob.notcell_arm = [frame_arm_notcell.x' frame_arm_notcell.y' frame_arm_notcell.z' frame_arm_notcell.origin';...
                                     0                    0                    0                    1              ];

% transforamtion matrix from global (Vicon) to local:
transf_mtx_GLOB_loc.notcell_arm = inv(transf_mtx_LOC_glob.notcell_arm);
% the inverse matrix should be equal to the multiplication of the rotation
% matrix transposed for the translation matrix with sign inverted (see pdf
% in this folder):
rot_transp = [transf_mtx_LOC_glob.notcell_arm(1:3,1:3).', [0;0;0];[0 0 0 1]];
transl_inv = [[eye(3,3); [0 0 0]] [-transf_mtx_LOC_glob.notcell_arm(1:3,4);1]]; % note: eye is the identity mtx
check2 = rot_transp * transl_inv; % check2 should be equal to transf_mtx_GLOB_loc.notcell_arm 
% unless the columns are not unit-length or not normal among them (which 
% means there is an error in the calculation of the frame vectors).


%% respective tweezers' tip position in frame_arm_notcell

tip_pos_arm_notcell.local = transf_mtx_GLOB_loc.notcell_arm * [tip_pos_arm_notcell.global.center 1]';


% check...

aa=frame_arm_notcell.origin;
figure, plot3(aa(1), aa(2), aa(3),'.','Color','#0fffff','MarkerSize',24) % cyan
bb=mean(marker.a_short);
hold on, plot3(bb(1), bb(2), bb(3),'.','Color','#ff13a6','MarkerSize',24) % pink
cc=mean(marker.a_long);
plot3(cc(1), cc(2), cc(3),'.','Color','#993d00','MarkerSize',24) % brown
dd=tip_pos_arm_notcell.global.center;
plot3(dd(1), dd(2), dd(3),'.k','MarkerSize',24) % tip
grid on

ee = aa + 40*frame_arm_notcell.x;
plot3([aa(1) ee(1)],[aa(2) ee(2)],[aa(3) ee(3)],'b-') % vector x
ff = aa + 40*frame_arm_notcell.y;
plot3([aa(1) ff(1)],[aa(2) ff(2)],[aa(3) ff(3)],'r-') % vector y
gg = aa + 40*frame_arm_notcell.z;
plot3([aa(1) gg(1)],[aa(2) gg(2)],[aa(3) gg(3)],'g-') % vector z

plot3([aa(1) dd(1)],[aa(2) dd(2)],[aa(3) dd(3)],'k-') % vector z


% COLORS: 
% cyan:   #0fffff
% pink:   #ff13a6
% brown:  #993d00
% dark green: #06942c
% dark blue:  #056aad
% red: r

clearvars aa bb cc dd ee ff gg









