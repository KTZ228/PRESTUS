function test_pass = kWaveDiffusion_compare_3D_homog_with_exact(plot_comparisons, plot_simulations) 
% DESCRIPTION:
%       Unit test to compare the k-Wave diffusion class with an exact
%       solution for Pennes' bioheat equation.
%
% ABOUT:
%       author      - Bradley Treeby
%       date        - 16th August 2015
%       last update - 11th December 2017
%       
% This function is part of the k-Wave Toolbox (http://www.k-wave.org)
% Copyright (C) 2015-2017 Bradley Treeby

% This file is part of k-Wave. k-Wave is free software: you can
% redistribute it and/or modify it under the terms of the GNU Lesser
% General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
% 
% k-Wave is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
% more details. 
% 
% You should have received a copy of the GNU Lesser General Public License
% along with k-Wave. If not, see <http://www.gnu.org/licenses/>.

% set pass variable
test_pass = true;

% set comparison threshold
COMPARISON_THRESH = 1e-13;

% check for plot inputs, and set to true if nargin is zero (to allow the
% test to be run independent of runUnitTests)
if nargin == 0
    plot_comparisons = true;
    plot_simulations = true;
end

% =========================================================================
% SIMULATION - NO SOURCE
% =========================================================================

% create grid
Nx = 64;
Ny = 64;
Nz = 64;
dx = 1e-3;
dy = 1e-3;
dz = 1e-3;
kgrid = kWaveGrid(Nx, dx, Ny, dy, Nz, dz);

% define medium properties
medium.density              = 1079;     % [kg/m^3]
medium.thermal_conductivity = 0.52;     % [W/(m.K)]
medium.specific_heat        = 3540;     % [J/(kg.K)]

% set Gaussian initial temperature distribution
offset = 0;
width = 4*dx;
source.T0 = 37 + exp(-( ((kgrid.x-offset)/width).^2 + ((kgrid.y-offset)/width).^2 + ((kgrid.z-offset)/width).^2 ));

% set input args
input_args = {'PlotSim', plot_simulations, 'PlotScale', [37, 38]};

% create kWaveDiffusion object:
kdiff = kWaveDiffusion(kgrid, medium, source, [], input_args{:});

% take time steps
Nt = 300;
dt = 0.5;
kdiff.takeTimeStep(Nt, dt);

% compare with Green's function solution
D  = medium.thermal_conductivity / (medium.density * medium.specific_heat);
T_exact = bioheatExact(source.T0, 0, [D, 0, 0], kgrid.dx, Nt*dt);

% compute the maximum error
error = abs(kdiff.T - T_exact);
L_inf = max(error(:));

% compute pass
if (L_inf > COMPARISON_THRESH)
    test_pass = false;
end

% =========================================================================
% PLOT COMPARISONS
% =========================================================================

if plot_comparisons

    figure;
    subplot(1, 3, 1);
    imagesc(squeeze(kdiff.T(:, :, Nz/2)));
    axis image;
    colorbar;
    title('k-Wave');

    subplot(1, 3, 2);
    imagesc(squeeze(T_exact(:, :, Nz/2)));
    axis image;
    colorbar;
    title('Exact solution');

    subplot(1, 3, 3);
    imagesc(squeeze(error(:, :, Nz/2)));
    axis image;
    colorbar;
    title('Error');
    
end

% =========================================================================
% SIMULATION - SOURCE
% =========================================================================

% set Gaussian heat source
x_offset = 15e-3;
y_offset = 15e-3;
z_offset = 0;
width = 3*dx;
source.Q = 3e4 * exp(-( ((kgrid.x-x_offset)/width).^2 + ((kgrid.y-y_offset)/width).^2 + ((kgrid.z-z_offset)/width).^2 ));

% create kWaveDiffusion object:
kdiff = kWaveDiffusion(kgrid, medium, source, [], input_args{:});

% take time steps
kdiff.takeTimeStep(Nt, dt);

% compare with Green's function solution
S = source.Q ./ (medium.density .* medium.specific_heat);
T_exact = bioheatExact(source.T0, S, [D, 0, 0], kgrid.dx, Nt*dt);

% compute the maximum error
error = abs(kdiff.T - T_exact);
L_inf = max(error(:));

% compute pass
if (L_inf > COMPARISON_THRESH)
    test_pass = false;
end

% =========================================================================
% PLOT COMPARISONS
% =========================================================================

if plot_comparisons

    figure;
    subplot(1, 3, 1);
    imagesc(squeeze(kdiff.T(:, :, Nz/2)));
    axis image;
    colorbar;
    title('k-Wave');

    subplot(1, 3, 2);
    imagesc(squeeze(T_exact(:, :, Nz/2)));
    axis image;
    colorbar;
    title('Exact solution');

    subplot(1, 3, 3);
    imagesc(squeeze(error(:, :, Nz/2)));
    axis image;
    colorbar;
    title('Error');
    
end