%% IEEE 33-Bus PV Placement — Main Script
clear; clc;

linedata = [
    1  2  0.0922  0.0470  100  60;
    2  3  0.4930  0.2511  90   40;
    3  4  0.3660  0.1864  120  80;
    4  5  0.3811  0.1941  60   30;
    5  6  0.8190  0.7070  60   20;
    6  7  0.1872  0.6188  200  100;
    7  8  0.7114  0.2351  200  100;
    8  9  1.0300  0.7400  60   20;
    9  10 1.0440  0.7400  60   20;
    10 11 0.1966  0.0650  45   30;
    11 12 0.3744  0.1238  60   35;
    12 13 1.4680  1.1550  60   35;
    13 14 0.5416  0.7129  120  80;
    14 15 0.5910  0.5260  60   10;
    15 16 0.7463  0.5450  60   20;
    16 17 1.2890  1.7210  60   20;
    17 18 0.7320  0.5740  90   40;
    2  19 0.1640  0.1565  90   40;
    19 20 1.5042  1.3554  90   40;
    20 21 0.4095  0.4784  90   40;
    21 22 0.7089  0.9373  90   40;
    3  23 0.4512  0.3083  90   50;
    23 24 0.8980  0.7091  420  200;
    24 25 0.8960  0.7011  420  200;
    6  26 0.2030  0.1034  60   25;
    26 27 0.2842  0.1447  60   25;
    27 28 1.0590  0.9337  60   20;
    28 29 0.8042  0.7006  120  70;
    29 30 0.5075  0.2585  200  600;
    30 31 0.9744  0.9630  150  70;
    31 32 0.3105  0.3619  210  100;
    32 33 0.3410  0.5302  60   40;
];

nbus = 33;

%% Baseline (no PV)
[V_base, P_loss_base] = runPowerFlow(linedata, nbus, 0, 0);
fprintf('Baseline total loss: %.4f kW\n', P_loss_base);

%% Spatial sweep
PV_kW  = 1000;
losses = zeros(nbus, 1);

for bus = 2:nbus
    [~, loss] = runPowerFlow(linedata, nbus, bus, PV_kW);
    losses(bus) = loss;
    fprintf('Bus %2d | Loss: %.4f kW\n', bus, loss);
end

%% Find best bus
[min_loss, best_idx] = min(losses(2:nbus));
best_bus = best_idx + 1;
fprintf('\nBest bus for PV: Bus %d\n', best_bus);
fprintf('Loss with PV:    %.4f kW\n', min_loss);
fprintf('Loss reduction:  %.2f%%\n', (P_loss_base - min_loss)/P_loss_base * 100);

%% Plot
figure;
bar(2:nbus, losses(2:nbus), 'FaceColor', [0.2 0.5 0.8]);
hold on;
yline(P_loss_base, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Baseline');
xlabel('Bus Number');
ylabel('Total Active Power Loss (kW)');
title('Power Loss vs PV Placement Location — IEEE 33-Bus');
grid on;

%% Stage 5 — PSO Optimisation
fprintf('\nRunning PSO optimisation...\n');
[opt_bus, opt_kW, opt_loss] = runPSO(linedata, nbus, P_loss_base);

%% Compare results
fprintf('\n========== SUMMARY ==========\n');
fprintf('Baseline loss:           %.4f kW\n', P_loss_base);
fprintf('Spatial sweep best loss: %.4f kW at Bus %d (1000 kW fixed)\n', min_loss, best_bus);
fprintf('PSO optimised loss:      %.4f kW at Bus %d (%.0f kW)\n', opt_loss, opt_bus, opt_kW);
fprintf('PSO loss reduction:      %.2f%%\n', (P_loss_base - opt_loss)/P_loss_base * 100);

%% Plot comparison
figure;
bar_data = [P_loss_base, min_loss, opt_loss];
bar(bar_data, 'FaceColor', 'flat', 'CData', [0.6 0.6 0.6; 0.2 0.5 0.8; 0.1 0.7 0.3]);
set(gca, 'XTickLabel', {'Baseline', 'Spatial Sweep', 'PSO Optimised'});
ylabel('Total Active Power Loss (kW)');
title('Loss Comparison — Baseline vs Spatial Sweep vs PSO');
grid on;

%% Voltage Profile Plot
% Run power flow for three scenarios
[V_base,  ~] = runPowerFlow(linedata, nbus, 0,       0);         % baseline
[V_sweep, ~] = runPowerFlow(linedata, nbus, 30,      1000);      % spatial sweep best
[V_pso,   ~] = runPowerFlow(linedata, nbus, opt_bus, opt_kW);    % PSO optimised

figure;
plot(1:nbus, V_base,  'r--o', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Baseline (no PV)');
hold on;
plot(1:nbus, V_sweep, 'b--s', 'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Spatial Sweep (Bus 30, 1000 kW)');
plot(1:nbus, V_pso,   'g-^',  'LineWidth', 2,   'MarkerSize', 4, 'DisplayName', sprintf('PSO Optimised (Bus %d, %.0f kW)', opt_bus, opt_kW));

% IEEE voltage limit lines
yline(0.95, 'k:', 'LineWidth', 1.2, 'DisplayName', 'Lower limit (0.95 pu)');
yline(1.05, 'k:', 'LineWidth', 1.2, 'DisplayName', 'Upper limit (1.05 pu)');

xlabel('Bus Number');
ylabel('Voltage Magnitude (pu)');
title('Voltage Profile — Baseline vs Spatial Sweep vs PSO Optimised');
legend('Location', 'southwest');
grid on;
xlim([1 nbus]);
ylim([0.88 1.06]);

%% Run PSO 6 times to test consistency
fprintf('\n========== PSO SENSITIVITY ANALYSIS (6 RUNS) ==========\n');

n_runs = 6;
results = zeros(n_runs, 3);  % [bus, kW, loss]

for run = 1:n_runs
    fprintf('\nRun %d...\n', run);
    [r_bus, r_kW, r_loss] = runPSO(linedata, nbus, P_loss_base);
    results(run, 1) = r_bus;
    results(run, 2) = r_kW;
    results(run, 3) = r_loss;
end

%% Print summary table
fprintf('\n========== SENSITIVITY ANALYSIS RESULTS ==========\n');
fprintf('Run | Optimal Bus | PV Size (kW) | Loss (kW) | Reduction\n');
fprintf('----|-------------|--------------|-----------|----------\n');
for run = 1:n_runs
    reduction = (P_loss_base - results(run,3)) / P_loss_base * 100;
    fprintf(' %d  |   Bus %2d     |   %7.2f    |  %7.4f  |  %.2f%%\n', ...
        run, results(run,1), results(run,2), results(run,3), reduction);
end

fprintf('\n--- Statistics ---\n');
fprintf('Mean loss:       %.4f kW\n', mean(results(:,3)));
fprintf('Std deviation:   %.4f kW\n', std(results(:,3)));
fprintf('Best loss:       %.4f kW\n', min(results(:,3)));
fprintf('Worst loss:      %.4f kW\n', max(results(:,3)));
fprintf('Mean reduction:  %.2f%%\n',  mean((P_loss_base - results(:,3))/P_loss_base*100));
