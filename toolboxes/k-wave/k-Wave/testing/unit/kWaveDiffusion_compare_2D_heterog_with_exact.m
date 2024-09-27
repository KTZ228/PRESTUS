function test_pass = kWaveDiffusion_compare_2D_heterog_with_exact(plot_comparisons, plot_simulations)
% DESCRIPTION:
%       Unit test to compare the k-Wave diffusion class with an exact
%       solution for Pennes' bioheat equation.
%
% ABOUT:
%       author      - Bradley Treeby
%       date        - 14th August 2015
%       last update - 26th July 2019
%       
% This function is part of the k-Wave Toolbox (http://www.k-wave.org)
% Copyright (C) 2015-2019 Bradley Treeby

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
COMPARISON_THRESH = 2e-5;

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
Nx = 128;
Ny = 128;
dx = 1e-3;
dy = 1e-3;
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% define medium properties
density_1              = 1079;  % [kg/m^3]
thermal_conductivity_1 = 0.52;  % [W/(m.K)]
specific_heat_1        = 3540;  % [J/(kg.K)]

density_2              = 1200;  % [kg/m^3]
thermal_conductivity_2 = 0.13;  % [W/(m.K)]
specific_heat_2        = 4000;  % [J/(kg.K)]

% define heterogeneous medium properties
medium.density              = density_1 .* ones(Nx, Ny);
medium.thermal_conductivity = thermal_conductivity_1 .* ones(Nx, Ny);
medium.specific_heat        = specific_heat_1 .* ones(Nx, Ny);

medium.density(kgrid.y > 0)              = density_2;
medium.thermal_conductivity(kgrid.y > 0) = thermal_conductivity_2;
medium.specific_heat(kgrid.y > 0)        = specific_heat_2;

% set initial temperature distribution
s1 = smooth(makeDisc(Nx, Ny, Nx/2, Ny/4, 5));
s2 = smooth(makeDisc(Nx, Ny, Nx/2, 3*Ny/4, 5));

% define source term
source.T0  = 37 + s1 + s2;

% set number of time steps
Nt = 300;
dt = 0.5;

% set input args
input_args = {'PlotSim', plot_simulations, 'PlotScale', [37, 38]};

% create kWaveDiffusion object and take time steps
medium.diffusion_coeff_ref = 'max';
kdiff_max = kWaveDiffusion(kgrid, medium, source, [], input_args{:});
kdiff_max.takeTimeStep(Nt, dt);

% create kWaveDiffusion object again using opposite reference value and
% take time steps 
medium.diffusion_coeff_ref = 'min';
kdiff_min = kWaveDiffusion(kgrid, medium, source, [], input_args{:});
kdiff_min.takeTimeStep(Nt, dt);

% compare with Green's function solution
D1  = thermal_conductivity_1 ./ (density_1 .* specific_heat_1);
T_exact1 = bioheatExact(37 + s1, 0, [D1, 0, 0], kgrid.dx, Nt*dt);

D2  = thermal_conductivity_2 ./ (density_2 .* specific_heat_2);
T_exact2 = bioheatExact(37 + s2, 0, [D2, 0, 0], kgrid.dx, Nt*dt);

T_exact = zeros(Nx, Ny);
T_exact(:, 1:Ny/2)     = T_exact1(:, 1:Ny/2);
T_exact(:, Ny/2+1:end) = T_exact2(:, Ny/2+1:end);

% calculate error
error_max = abs(kdiff_max.T - T_exact);
error_min = abs(kdiff_min.T - T_exact);

% error using the exact solution for each side
error_best = [error_max(:, 1:Ny/2), error_min(:, Ny/2+1:end)];

% compute the maximum error
L_inf = max(error_best(:));

% compute pass
if (L_inf > COMPARISON_THRESH)
    test_pass = false;
end

% =========================================================================
% PLOT COMPARISONS
% =========================================================================

if plot_comparisons

    figure;
    
    subplot(2, 3, 1);
    imagesc(kdiff_max.T);
    axis image;
    colorbar;
    title('k-Wave with Dref max (matches left side)');

    subplot(2, 3, 2);
    imagesc(kdiff_min.T);
    axis image;
    colorbar;
    title('k-Wave with Dref min (matches right side)');    
    
    subplot(2, 3, 3);
    imagesc(T_exact);
    axis image;
    colorbar;
    title('Exact solution');

    subplot(2, 3, 4);
    imagesc(abs(T_exact - kdiff_max.T));
    axis image;
    colorbar;
    title('Error with Dref max');

    subplot(2, 3, 5);
    imagesc(abs(T_exact - kdiff_min.T));
    axis image;
    colorbar;
    title('Error with Dref min');
    
    subplot(2, 3, 6);
    imagesc(error_best);
    axis image;
    colorbar;
    title('Error with correct ref for each half');  
    
end

% =========================================================================
% SIMULATION - SOURCE
% =========================================================================

% set Gaussian heat source
offset = 30e-3;
width = 3*dx;
source.Q = 3e4 * exp(-( ((kgrid.x-offset)/width).^2 + ((kgrid.y-offset)/width).^2 ));

% create kWaveDiffusion object and take time steps
medium.diffusion_coeff_ref = 'max';
kdiff_max = kWaveDiffusion(kgrid, medium, source, [], input_args{:});
kdiff_max.takeTimeStep(Nt, dt);

% create kWaveDiffusion object again using opposite reference value and
% take time steps 
medium.diffusion_coeff_ref = 'min';
kdiff_min = kWaveDiffusion(kgrid, medium, source, [], input_args{:});
kdiff_min.takeTimeStep(Nt, dt);

% compare with Green's function solution
S = source.Q ./ (medium.density .* medium.specific_heat);
T_exact1 = bioheatExact(37 + s1, S, [D1, 0, 0], kgrid.dx, Nt*dt);
T_exact2 = bioheatExact(37 + s2, S, [D2, 0, 0], kgrid.dx, Nt*dt);

T_exact = zeros(Nx, Ny);
T_exact(:, 1:Ny/2)     = T_exact1(:, 1:Ny/2);
T_exact(:, Ny/2+1:end) = T_exact2(:, Ny/2+1:end);

% calculate error
error_max = abs(kdiff_max.T - T_exact);
error_min = abs(kdiff_min.T - T_exact);

% error using the exact solution for each side
error_best = [error_max(:, 1:Ny/2), error_min(:, Ny/2+1:end)];

% compute the maximum error
L_inf = max(error_best(:));

% compute pass
if (L_inf > COMPARISON_THRESH)
    test_pass = false;
end

% =========================================================================
% PLOT COMPARISONS
% =========================================================================

if plot_comparisons

    figure;
    
    subplot(2, 3, 1);
    imagesc(kdiff_max.T);
    axis image;
    colorbar;
    title('k-Wave with Dref max (matches left side)');

    subplot(2, 3, 2);
    imagesc(kdiff_min.T);
    axis image;
    colorbar;
    title('k-Wave with Dref min (matches right side)');    
    
    subplot(2, 3, 3);
    imagesc(T_exact);
    axis image;
    colorbar;
    title('Exact solution');

    subplot(2, 3, 4);
    imagesc(abs(T_exact - kdiff_max.T));
    axis image;
    colorbar;
    title('Error with Dref max');

    subplot(2, 3, 5);
    imagesc(abs(T_exact - kdiff_min.T));
    axis image;
    colorbar;
    title('Error with Dref min');
    
    subplot(2, 3, 6);
    imagesc(error_best);
    axis image;
    colorbar;
    title('Error with correct ref for each half');  
    
end