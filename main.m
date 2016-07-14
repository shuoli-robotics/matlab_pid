clear
clc

global k_F k_M L m g I_xx I_yy I_zz I matrix_force_2_omega
global waypoint_relative state

%------------------------------------------------------
%                  model parameter
%------------------------------------------------------
k_F = 6.11*10^-8;
k_M = 1.5*10^-9;
L = 0.175;
I_xx = 2.32*10^-3;
I_yy = 2.32*10^-3;
I_zz = 4.00*10^-3;
m = 0.5;
g = 9.8;
I = [I_xx 0 0; 0 I_yy 0; 0 0 I_zz];

state_initial = [0 0 3 0 2 0 0 0 pi/2 0 0 0];  % local coor

%------------------------------------------------------
%                    PID parameter
%------------------------------------------------------
          con_P_phi = 0.06;
          con_I_phi = 0;
          con_D_phi = 0.02;
          
          con_P_theta = 0.055;
          con_I_theta = 0;
          con_D_theta = 0.025;
          
          con_P_psi = 0.02;
          con_I_psi = 0;
          con_D_psi = 0.02;
          
          con_P_z = 5;
          con_I_z = 0.2;
          con_D_z = 4;
%------------------------------------------------------
 
%------------------------------------------------------
%                 Generate global map
%------------------------------------------------------
map = zeros(3,10);
for i = 1:10
    map(1,i) = 2.5+(-0.5+1*rand());
    map(2,i) = 5*i;  %+(-2+4*rand());
    map(3,i) = 3+(-0.5+1*rand());
end
% for i = 1:3
%     map(1,i+10) = 13.5-3*i;
%     map(2,i+10) = 55;  %+(-2+4*rand());
%     map(3,i+10) = 3+(-0.5+1*rand());
%       
% end
% 
% for i = 1:10
%     map(1,i+13) = 1.5+(-0.5+1*rand());
%     map(2,i+13) = 50 - 5*(i-1);  %+(-2+4*rand());
%     map(3,i+13) = 3+(-0.5+1*rand());
% end

for i = 1:size(map,2) 
    axis equal;
    axis([0 5 0 55 0 6]);
    plot3(map(1,i),map(2,i),map(3,i),'*');
    hold on;
    plot_obstacle( [map(1,i) map(2,i) map(3,i)],1);
    grid on;
end

matrix_omega_2_force = [k_F k_F k_F k_F; 0 k_F*L 0 -k_F*L;...
    -k_F*L 0 k_F*L 0; k_M -k_M k_M -k_M];
matrix_force_2_omega = inv(matrix_omega_2_force);

local_coordinate_psi = 0;
local_coordinate_origin = [2.5 0 0]';
global_position = [];

for j = 1:size(map,2)
    if j == 10
        temp = 1;
    end
    state = state_initial;  % used in guidance.m not too much

    %%waypoint_relative = [-3 5 4];  %% local
    %%% choose the waypoint
    [waypoint_relative] = choose_waypoint(map(1:3,j),...
        local_coordinate_origin,local_coordinate_psi);

    sim('pid_simulation');

    % check if it is right in local coor
    figure(5)
    plot3(local_state(:,1),local_state(:,2),local_state(:,3),'b','LineWidth',2);
    grid on;
    hold on;
    plot3(ref(:,1),ref(:,2),ref(:,3),'--r','LineWidth',2);
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');

    C = [cos(-local_coordinate_psi) sin(-local_coordinate_psi) 0;...
    -sin(-local_coordinate_psi) cos(-local_coordinate_psi) 0;...
    0 0 1];   % convert position in local coor to global coor


    for i = 1:size(local_state,1)
        global_position_temp(i,[1:3]) = [C*[local_state(i,1) local_state(i,2) local_state(i,3)]'...
        + local_coordinate_origin]';
    end
    figure(1);
    plot3(global_position_temp(:,1),global_position_temp(:,2),global_position_temp(:,3),'b','LineWidth',2);
    global_position = [global_position;global_position_temp];
    global_position_temp = [];
    figure(1);
    grid on;
    hold on;
    xlabel('x(m)');
    ylabel('y(m)');
    zlabel('z(m)');

    %--------------------------------------------------------------------------
    %                 update new local coordinate for next step
    %--------------------------------------------------------------------------

    % calculte origin of new coordinate
    local_coordinate_origin = C*[local_state(end,1) local_state(end,2) local_state(end,3)]'...
    + local_coordinate_origin;
    local_coordinate_origin(3) = 0;

    % calculate heading angle of new coordinate
    derta_psi_local_coordinate = local_state(end,9)-state_initial(9);
    local_coordinate_psi = local_coordinate_psi + derta_psi_local_coordinate;

    %---------------------------------------------------------
    %  update initial state for new local coordinate
    %---------------------------------------------------------
    state_initial(1) = 0;
    state_initial(2) = 0;
    state_initial(3) = local_state(end,3);
    state_initial(4) = 0;
    state_initial(5) = norm([local_state(end,4) local_state(end,5) local_state(end,6)]);
    state_initial(6) = 0;
    state_initial(7:8) = local_state(end,7:8);
    state_initial(9) = pi/2;
    state_initial(10:12) = local_state(end,10:12); 
%---------------------------------------------------------
end

temp = 0;
