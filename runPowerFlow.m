function [V_pu, Ploss_kW] = runPowerFlow(linedata, nbus, PV_bus, PV_kW)

    Vbase_kV = 12.66;
    Sbase_kVA = 10000;  % 10 MVA base
    Zbase = (Vbase_kV^2) / (Sbase_kVA/1000);  % = 16.02 ohms

    nb = size(linedata,1);

    % Loads in per unit
    P_pu = zeros(nbus,1);
    Q_pu = zeros(nbus,1);
    for i = 1:nb
        tb = linedata(i,2);
        P_pu(tb) = P_pu(tb) + (linedata(i,5)/1000) / (Sbase_kVA/1000);
        Q_pu(tb) = Q_pu(tb) + (linedata(i,6)/1000) / (Sbase_kVA/1000);
    end

    % PV injection
    if PV_bus > 1
        P_pu(PV_bus) = P_pu(PV_bus) - (PV_kW/1000) / (Sbase_kVA/1000);
    end

    % Branch impedances in per unit
    R_pu = linedata(:,3) / Zbase;
    X_pu = linedata(:,4) / Zbase;

    % Initialise
    V_pu = ones(nbus,1);
    max_iter = 100;
    tol = 1e-6;

    for iter = 1:max_iter
        V_old = V_pu;

        % Backward sweep — branch power flows
        P_branch = zeros(nb,1);
        Q_branch = zeros(nb,1);
        for k = nb:-1:1
            tb = linedata(k,2);
            P_branch(k) = P_pu(tb);
            Q_branch(k) = Q_pu(tb);
            % Add downstream branch losses
            for m = 1:nb
                if linedata(m,1) == tb
                    P_branch(k) = P_branch(k) + P_branch(m) + R_pu(m)*(P_branch(m)^2 + Q_branch(m)^2)/V_pu(tb)^2;
                    Q_branch(k) = Q_branch(k) + Q_branch(m) + X_pu(m)*(P_branch(m)^2 + Q_branch(m)^2)/V_pu(tb)^2;
                end
            end
        end

        % Forward sweep — update voltages
        for k = 1:nb
            fb = linedata(k,1);
            tb = linedata(k,2);
            V_pu(tb)^2;
            V_sq = V_pu(fb)^2 ...
                - 2*(R_pu(k)*P_branch(k) + X_pu(k)*Q_branch(k)) ...
                + (R_pu(k)^2 + X_pu(k)^2)*(P_branch(k)^2 + Q_branch(k)^2)/V_pu(fb)^2;
            V_pu(tb) = sqrt(max(V_sq, 0.5));
        end
        V_pu(1) = 1.0;

        if max(abs(V_pu - V_old)) < tol
            break;
        end
    end

    % Total loss in kW
    Ploss_kW = 0;
    for k = 1:nb
        Ploss_kW = Ploss_kW + R_pu(k) * (P_branch(k)^2 + Q_branch(k)^2) / V_pu(linedata(k,1))^2 * Sbase_kVA;
    end

end