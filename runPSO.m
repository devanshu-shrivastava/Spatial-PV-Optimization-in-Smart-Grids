function [best_bus, best_kW, best_loss] = runPSO(linedata, nbus, baseline_loss)

    %% PSO Parameters
    n_particles = 30;
    max_iter    = 100;
    w           = 0.7;    % inertia weight
    c1          = 1.5;    % cognitive coefficient
    c2          = 1.5;    % social coefficient

    % Search space
    bus_min = 2;       bus_max = nbus;      % bus location
    kW_min  = 100;     kW_max  = 3000;      % PV size in kW

    %% Initialise particles
    % Each particle has 2 dimensions: [bus, PV_size]
    pos = zeros(n_particles, 2);
    vel = zeros(n_particles, 2);

    for i = 1:n_particles
        pos(i,1) = randi([bus_min, bus_max]);         % random bus
        pos(i,2) = kW_min + rand*(kW_max - kW_min);  % random PV size
        vel(i,1) = rand * 2;
        vel(i,2) = rand * 100;
    end

    %% Evaluate initial fitness
    pbest_pos  = pos;
    pbest_cost = zeros(n_particles, 1);

    for i = 1:n_particles
        bus = round(pos(i,1));
        bus = max(bus_min, min(bus_max, bus));
        kW  = pos(i,2);
        [~, loss] = runPowerFlow(linedata, nbus, bus, kW);
        pbest_cost(i) = loss;
    end

    % Global best
    [gbest_cost, idx] = min(pbest_cost);
    gbest_pos = pbest_pos(idx, :);

    fprintf('\n--- PSO Optimisation Starting ---\n');
    fprintf('Baseline loss: %.4f kW\n\n', baseline_loss);

    %% Main PSO loop
    for iter = 1:max_iter

        for i = 1:n_particles
            r1 = rand;
            r2 = rand;

            % Update velocity
            vel(i,:) = w  * vel(i,:) ...
                     + c1 * r1 * (pbest_pos(i,:) - pos(i,:)) ...
                     + c2 * r2 * (gbest_pos      - pos(i,:));

            % Update position
            pos(i,:) = pos(i,:) + vel(i,:);

            % Clamp to bounds
            pos(i,1) = max(bus_min, min(bus_max, pos(i,1)));
            pos(i,2) = max(kW_min,  min(kW_max,  pos(i,2)));

            % Evaluate fitness
            bus = round(pos(i,1));
            kW  = pos(i,2);
            [~, loss] = runPowerFlow(linedata, nbus, bus, kW);

            % Update personal best
            if loss < pbest_cost(i)
                pbest_cost(i)  = loss;
                pbest_pos(i,:) = pos(i,:);
            end

            % Update global best
            if loss < gbest_cost
                gbest_cost = loss;
                gbest_pos  = pos(i,:);
            end
        end

        % Print progress every 10 iterations
        if mod(iter, 10) == 0
            fprintf('Iteration %3d | Best loss so far: %.4f kW\n', iter, gbest_cost);
        end
    end

    %% Results
    best_bus  = round(gbest_pos(1));
    best_kW   = gbest_pos(2);
    best_loss = gbest_cost;

    fprintf('\n--- PSO Results ---\n');
    fprintf('Optimal bus:       Bus %d\n',   best_bus);
    fprintf('Optimal PV size:   %.2f kW\n',  best_kW);
    fprintf('Optimal loss:      %.4f kW\n',  best_loss);
    fprintf('Loss reduction:    %.2f%%\n',   (baseline_loss - best_loss)/baseline_loss * 100);

end

