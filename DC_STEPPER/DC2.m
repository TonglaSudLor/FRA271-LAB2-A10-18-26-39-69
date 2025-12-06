% --- 1. ตั้งค่า Lookup Table (มีจุด 0,0 เพื่อรองรับกระแสต่ำ) ---
lookup_current = [0, 2, 2.34, 2.56, 2.884, 3.13, 3.336, 3.594, 3.706, 3.927, 4.375, 4.475, 4.607];
lookup_torque  = [0, 0.0015, 0.015, 0.028, 0.03975, 0.05575, 0.068, 0.08, 0.094, 0.1065, 0.11925, 0.134, 0.1465];

% รายชื่อตัวแปร
var_names = {'dc2100', 'dc2500', 'dc21000', 'dc23000'};
legend_labels = {'100 Hz', '500 Hz', '1000 Hz', '3000 Hz'};
line_colors = lines(4); 

% --- 2. สร้างกราฟเตรียมไว้ 3 หน้าต่าง ---

% กราฟที่ 1: Motor Current vs PWM (เอาตามที่ขอคืนมา)
fig_curr = figure('Name', 'Current vs PWM', 'Color', 'k');
ax_curr = axes(fig_curr); hold(ax_curr, 'on'); grid(ax_curr, 'on');
xlabel(ax_curr, 'PWM Duty Cycle (%)'); ylabel(ax_curr, 'Motor Current (A)');
title(ax_curr, 'Motor Current vs PWM Duty Cycle');

% กราฟที่ 2: Speed vs PWM
fig_speed = figure('Name', 'Speed vs PWM', 'Color', 'k');
ax_speed = axes(fig_speed); hold(ax_speed, 'on'); grid(ax_speed, 'on');
xlabel(ax_speed, 'PWM Duty Cycle (%)'); ylabel(ax_speed, 'Speed (RPM)');
title(ax_speed, 'Motor Speed vs PWM Duty Cycle');

% กราฟที่ 3: Efficiency vs PWM
fig_eff = figure('Name', 'Efficiency vs PWM', 'Color', 'k');
ax_eff = axes(fig_eff); hold(ax_eff, 'on'); grid(ax_eff, 'on');
xlabel(ax_eff, 'PWM Duty Cycle (%)'); ylabel(ax_eff, 'Efficiency (%)');
title(ax_eff, 'Calculated Efficiency vs PWM Duty Cycle');

% --- 3. วนลูปประมวลผลข้อมูลแต่ละชุด ---
for i = 1:length(var_names)
    try
        data = evalin('base', var_names{i});
        
        % ดึงค่าดิบ
        raw_current = double(squeeze(data{1}.Values.Data));
        raw_duty    = double(squeeze(data{5}.Values.Data));
        raw_speed   = double(squeeze(data{6}.Values.Data));
        
        % แปลง Duty เป็น %
        duty_percent = (raw_duty / 65535) * 100;
        
        % เรียงลำดับ (Sorting)
        [duty_sorted, sort_idx] = sort(duty_percent);
        current_sorted = raw_current(sort_idx);
        speed_sorted   = raw_speed(sort_idx);
        
        % กรองสัญญาณ (Smooth) ให้เรียบก่อนคำนวณ
        current_smooth = smoothdata(current_sorted, 'rlowess', 300);
        speed_smooth   = smoothdata(speed_sorted, 'rlowess', 300);
        
        % --- คำนวณ Torque ---
        torque_load = interp1(lookup_current, lookup_torque, current_smooth, 'linear', 'extrap');
        torque_load(torque_load < 0) = 0; 
        
        % --- คำนวณ Efficiency ---
        % ตัวเศษ: Power Output (Mechanical)
        numerator = (speed_smooth ./ 0.22254) .* (torque_load.^2) + (speed_smooth .* torque_load);
        
        % ตัวหาร: Power Input (Electrical) -> 12V * (Duty/100) * Current
        denominator = 12 .* (duty_sorted ./ 100) .* current_smooth;
        
        % คำนวณและคูณ 100 เพื่อเป็น %
        efficiency = (numerator ./ denominator) * 10000;
        
        % แก้ค่า Infinity/NaN (0/0) ให้เป็น 0
        efficiency(isinf(efficiency) | isnan(efficiency)) = 0;
        
        % กรอง Efficiency ให้กราฟเนียน
        efficiency_smooth = smoothdata(efficiency, 'movmean', 500); 

        % --- 4. พล็อตลงกราฟทั้ง 3 ---
        
        % Plot 1: Current
        plot(ax_curr, duty_sorted, current_smooth, '-', 'LineWidth', 2, ...
             'Color', line_colors(i,:), 'DisplayName', legend_labels{i});
         
        % Plot 2: Speed
        plot(ax_speed, duty_sorted, speed_smooth, '-', 'LineWidth', 2, ...
             'Color', line_colors(i,:), 'DisplayName', legend_labels{i});
         
        % Plot 3: Efficiency
        plot(ax_eff, duty_sorted, efficiency_smooth, '-', 'LineWidth', 2, ...
             'Color', line_colors(i,:), 'DisplayName', legend_labels{i});
             
    catch ME
        warning('Error: %s', ME.message);
    end
end

% --- 5. ตกแต่งกราฟ ---

% ตกแต่ง Current
legend(ax_curr, 'show', 'Location', 'best');
xlim(ax_curr, [0 100]);
ylim(ax_curr, [0, max(ylim(ax_curr))*1.1]);

% ตกแต่ง Speed
legend(ax_speed, 'show', 'Location', 'best');
xlim(ax_speed, [0 100]);

% ตกแต่ง Efficiency
legend(ax_eff, 'show', 'Location', 'best');
xlim(ax_eff, [0 100]);
% ปรับแกน Y ของ Efficiency (0 ถึง 100%)
ylim(ax_eff, [0, 100]); 
% ถ้ากราฟขึ้นไม่ถึง 100 และอยากให้ Auto Scale ให้แก้บรรทัดบนเป็น:
% ylim(ax_eff, [0, max(ylim(ax_eff))*1.1]);