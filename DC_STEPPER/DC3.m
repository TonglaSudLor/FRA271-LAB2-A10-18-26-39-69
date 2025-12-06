%% 1. ตั้งค่าตัวแปร (Configuration)
% ใส่ชื่อตัวแปร Workspace ให้ครบทั้ง 3 รอบ
% กลุ่ม Sign-Magnitude
group1_vars = {DC3_1, DC3_2, DC3_3}; 
group1_name = 'Sign-Magnitude';

% กลุ่ม Anti-Lock Phase
group2_vars = {DC31_1, DC31_2, DC31_3}; 
group2_name = 'Lock-Anti Phase';

%% 2. ประมวลผลหาค่าเฉลี่ย (Processing)
% เรียกฟังก์ชันดึงค่าและเฉลี่ย
[avg_pwm_1, avg_speed_1, avg_current_1] = process_and_average(group1_vars);
[avg_pwm_2, avg_speed_2, avg_current_2] = process_and_average(group2_vars);

%% 3. กราฟที่ 1: ความเร็ว vs PWM (Average)
figure('Name', 'Avg Comparison: Speed vs PWM', 'Color', 'k');
hold on; grid on;

plot(avg_pwm_1, avg_speed_1, 'b-', 'LineWidth', 1.5, 'DisplayName', group1_name);
plot(avg_pwm_2, avg_speed_2, 'r--', 'LineWidth', 1.5, 'DisplayName', group2_name);

xlabel('PWM Range');
ylabel('Average Speed (RPM)');
title('Average Motor Speed vs PWM');
legend('show', 'Location', 'best');
hold off;

%% 4. กราฟที่ 2: กระแส vs ความเร็ว (Average) <--- กลับมาเป็น Speed
figure('Name', 'Avg Comparison: Current vs Speed', 'Color', 'k');
hold on; grid on;

% ใช้ avg_speed เป็นแกน X
plot(avg_speed_1, avg_current_1, 'b-', 'LineWidth', 1.5, 'DisplayName', group1_name);
plot(avg_speed_2, avg_current_2, 'r--', 'LineWidth', 1.5, 'DisplayName', group2_name);

xlabel('Average Speed (RPM)');      % แกน X กลับมาเป็น Speed
ylabel('Average Current (A)');    % แกน Y เป็น Current
title('Average Current vs Speed');
legend('show', 'Location', 'best');
hold off;

%% ---------------------------------------------------------
%  Local Function: ฟังก์ชันรวม 3 ไฟล์และหาค่าเฉลี่ย
%  ---------------------------------------------------------
function [common_pwm, mean_speed, mean_current] = process_and_average(vars)
    num_trials = length(vars);
    
    % หาขอบเขต PWM ร่วมกัน
    min_p = -inf; max_p = inf;
    for i = 1:num_trials
        raw_p = squeeze(vars{i}{4}.Values.Data);
        if i==1, min_p = min(raw_p); max_p = max(raw_p);
        else, min_p = max(min_p, min(raw_p)); max_p = min(max_p, max(raw_p));
        end
    end
    
    % สร้างแกน PWM กลาง (ความละเอียด 1000 จุด)
    common_pwm = linspace(min_p, max_p, 1000)';
    
    speed_stack = zeros(length(common_pwm), num_trials);
    current_stack = zeros(length(common_pwm), num_trials);
    
    for i = 1:num_trials
        data = vars{i};
        
        raw_current = squeeze(data{1}.Values.Data);
        raw_pwm     = squeeze(data{4}.Values.Data);
        raw_speed   = squeeze(data{5}.Values.Data);
        
        % Sort & Unique ข้อมูลตามแกน PWM ก่อน Interp
        [sorted_pwm, sort_idx] = sort(raw_pwm);
        sorted_speed   = raw_speed(sort_idx);
        sorted_current = raw_current(sort_idx);
        
        [unique_pwm, unique_idx] = unique(sorted_pwm);
        unique_speed   = sorted_speed(unique_idx);
        unique_current = sorted_current(unique_idx);
        
        % Interpolate ลงแกนกลาง
        speed_stack(:, i) = interp1(unique_pwm, unique_speed, common_pwm, 'linear', 'extrap');
        current_stack(:, i) = interp1(unique_pwm, unique_current, common_pwm, 'linear', 'extrap');
    end
    
    % หาค่าเฉลี่ย
    mean_speed = mean(speed_stack, 2);
    mean_current = mean(current_stack, 2);
end