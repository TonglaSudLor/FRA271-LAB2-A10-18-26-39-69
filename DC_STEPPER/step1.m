% 1. เพิ่ม 'full_step' เข้าไปในรายการตัวแปรและชื่อใน Legend
base_names = {'full_step', 'half_step', 'step_1_4', 'step_1_8', 'step_1_16'};
legend_names = {'Full Step', 'Half Step', '1/4 Step', '1/8 Step', '1/16 Step'};

% กำหนดสีเส้น (5 สี)
colors = lines(5); 

figure;
hold on; grid on;

for i = 1:length(base_names)
    
    all_steps = [];
    all_vels = [];
    
    % วนลูป 3 การทดลอง
    for trial = 1:3
        % สร้างชื่อตัวแปร (เช่น full_step, full_step_2, full_step_3)
        if trial == 1
            var_name = base_names{i};
        else
            var_name = sprintf('%s_%d', base_names{i}, trial);
        end
        
        try
            current_data = eval(var_name); 
            
            raw_vel = double(squeeze(current_data{1}.Values.Data));
            raw_step = double(squeeze(current_data{4}.Values.Data));
            
            % [แก้ 1] รีเซ็ตให้ Step เริ่มต้นที่ 0 (แก้กราฟซ้อนกันผิดที่)
            raw_step = raw_step - raw_step(1);
            
            % [แก้ 2] ตัดช่วงกราฟขาลงทิ้ง (แก้กราฟดิ่งลงพื้น)
            [~, max_idx] = max(raw_vel);
            
            % เอาเฉพาะข้อมูลขาขึ้น (Ramp Up)
            valid_idx = 1:max_idx; 
            
            all_vels = [all_vels; raw_vel(valid_idx)];
            all_steps = [all_steps; raw_step(valid_idx)];
            
        catch
            % warning('หาตัวแปร %s ไม่เจอ', var_name);
        end
    end
    
    % คำนวณค่าเฉลี่ยรวมและพล็อต
    if ~isempty(all_steps)
        [unique_steps, ~, idx] = unique(all_steps);
        grand_avg_vel = accumarray(idx, all_vels, [], @mean);
        
        plot(unique_steps, grand_avg_vel, '-', ...
             'LineWidth', 2, ...
             'Color', colors(i,:), ...
             'DisplayName', legend_names{i});
    end
end

xlabel('Step Input');
ylabel('Velocity (rpm)');
title('Stepper Motor Velocity Comparison (All Steps)');
legend('Location', 'best');
hold off;