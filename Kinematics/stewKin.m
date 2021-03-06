clc; close all; clear all;
% Sources:
% https://www.instructables.com/id/Stewart-Platform/
% https://www.xarg.org/paper/inverse-kinematics-of-a-stewart-platform/

% --- Stewart platform design/input parameters ---
% Platform radius [m]
Rp = 0.1;

% Base radius [m]
Rb = 0.12;

% Horn length [m]
a = 0.05;

% Rod length [m]
s = 0.2;

% Angles of base plate joints
% DO NOT TOUCH
baseAngles = [0 60 120 180 240 300];
baseAngles = deg2rad(baseAngles);

% Angles of platform joints
% platAngles = [30 30 150 150 270 270];	% Triangle legs
platAngles = [0 60 120 180 240 300];	% Equispaced legs
platAngles = deg2rad(platAngles);

% Position of platform centroid (relative to base centroid) [m]
T = [0, 0, 0.17]';

% Platform angles (x, y, z) [deg]
Pang = [0, 0, 0];
Pang = deg2rad(Pang);

% --- Calculate rod vectors ---
% Calculate rod-platform joints (platform coords.)
P = zeros(3, 6);
P(1, :) = Rp .* cos(platAngles);
P(2, :) = Rp .* sin(platAngles);

% Calculate base-rod joints (base coords.)
B = zeros(3, 6);
B(1, :) = Rb .* cos(baseAngles);
B(2, :) = Rb .* sin(baseAngles);

% --- Define kinematic matrices ---
ProtB = @(phi, theta, psi) ...
   [cos(psi) * cos(theta),     -sin(psi) * cos(phi) + cos(psi) * sin(theta) * sin(phi),    sin(psi) * sin(phi) + cos(psi) * sin(theta) * cos(phi); ...
    sin(psi) * cos(theta),      cos(psi) * cos(phi) + sin(psi) * sin(theta) * sin(phi),   -cos(psi) * sin(phi) + sin(psi) * sin(theta) * cos(phi); ...
   -sin(theta)           ,      cos(theta) * sin(phi)                                 ,    cos(theta) * cos(phi)];

% --- Compute reverse kinematics ---
% Leg length matrix
L = zeros(3, 6);

% Origin
O = [0 0 0]';

% Transform platform vectors
for ii = 1:6
   Pxyz(:, ii) = ProtB(Pang(1), Pang(2), Pang(3)) * P(:, ii); 
end

% Calculate leg vectors
for ii = 1:6
    L(:, ii) = T + Pxyz(:, ii) - B(:, ii);
end
Llen = sqrt(sum(L.^2));

% Find tau vectors
tau = zeros(3, 6);
alph = zeros(1, 6);
beta = deg2rad([90 -30 -150 90 -30 -150])';

for n = 1:6
    taun = cross(B(:, n), [0 0 1]');
    % Convert to unit vector
    taun /= norm(taun);
    % Invert if odd
    if rem(n, 2)
        taun *= -1;
    end
    tau(:, n) = taun;
end

A = zeros(3, 6);
for n = 1:6
    % l = Llen(n);
    l = L(:, n);
    taun = tau(:, n);

    % Calculate servo angles
    betan = beta(n);

    en = 2 * a * l(3);
    fn = 2 * a * (cos(betan) * l(1) + sin(betan) * l(2));
    gn = (norm(l))^2 - (s^2 - a^2);
    alphn = asin(gn / sqrt(en^2 + fn^2)) - atan2(fn, en);
    alph(n) = alphn;

    % Calculate servo vectors
    A(:, n) = B(:, n) + a * [cos(alphn) * cos(betan); ...
                             cos(alphn) * sin(betan); ...
                             sin(alphn)];
end

% Calculate rod vectors
S = L - (A - B);

hold on;

for ii = 1:6
    % Plot platform vectors
    plotVec(T, Pxyz(:, ii) + T, 'r');

    % Plot base vectors
    plotVec(O, B(:, ii), 'g');

    % Plot l-vectors
    plotVec(B(:, ii), B(:, ii) + L(:, ii), 'b');

    % Plot tangent vectors
    % plotVec(B(:, ii), B(:, ii) + tau(:, ii), 'k');

    % Plot servo horns
    plotVec(B(:, ii), A(:, ii), 'k');

    % Plot rod vectors
    plotVec(A(:, ii), S(:, ii) + A(:, ii), 'k');
end


pbaspect([1 1 1]);
xlabel('x [m]');
ylabel('y [m]');
zlabel('z [m]');
xlim([-0.2 0.2]);
ylim([-0.2 0.2]);
zlim([-0.1 0.2]);

disp('Linkage lengths:');
for ii = 1:6
    disp(['Link ' num2str(ii) ': ' num2str(Llen(ii)) ' m']);
end

disp('');

disp('Servo angles: ');
for ii = 1:6
    disp(['Servo ' num2str(ii) ': ' num2str(rad2deg(alph(ii))) ' deg']);
end

disp('');