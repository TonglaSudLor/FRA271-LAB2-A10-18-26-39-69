% --- 1. ดึงข้อมูล, แก้ไขมิติ (Squeeze), และทำ Absolute ---

% ใช้ squeeze() เพื่อแก้ Error "more than 2 dimensions"
% และทำ abs() เพื่อให้ค่าเป็นบวกทั้งหมด
steps_cont_raw = squeeze(continuous{5}.Values.Data);
vel_cont_raw   = abs(squeeze(continuous{7}.Values.Data));

steps_disc_raw = squeeze(discrete{5}.Values.Data);
vel_disc_raw   = abs(squeeze(discrete{7}.Values.Data));

% --- 2. ฟังก์ชันกรองข้อมูล (ตัดค่าที่ความเร็วเท่าเดิมออก) ---
function [steps_clean, vel_clean] = filter_repeated_velocity(steps, vel)
    % หาผลต่างของความเร็วเทียบกับจุดก่อนหน้า (Derivative)
    d_vel = [1; diff(vel)]; % ใส่ 1 ตัวแรกเพื่อเก็บจุดเริ่มต้นไว้
    
    % เลือกเฉพาะจุดที่ความเร็วมีการเปลี่ยนแปลง (diff ไม่เป็น 0)
    % ใช้ Tolerance นิดหน่อยเผื่อเป็นเลขทศนิยม (1e-6)
    mask = abs(d_vel) > 1e-6;
    
    % ดึงข้อมูลเฉพาะจุดที่ผ่านเงื่อนไข
    steps_clean = steps(mask);
    vel_clean = vel(mask);
end

% เรียกใช้ฟังก์ชันกรองข้อมูล
[steps_cont, vel_cont] = filter_repeated_velocity(steps_cont_raw, vel_cont_raw);
[steps_disc, vel_disc] = filter_repeated_velocity(steps_disc_raw, vel_disc_raw);

% --- 3. การสร้างกราฟ ---
figure('Name', 'Stepper Acceleration (No Steady State)', 'Color', 'w');
hold on;
grid on;

% พล็อตแบบ Continuous (ค่อยๆ เร่ง)
plot(steps_cont, vel_cont, 'b-', 'LineWidth', 2, ...
    'DisplayName', 'Gradual Acceleration');

% พล็อตแบบ Discrete (เร่งทันที)
% พอเราตัดค่าซ้ำออก เส้นจะเชื่อมจุดที่มีการเปลี่ยนความเร็วเข้าหากัน
plot(steps_disc, vel_disc, 'r--o', 'LineWidth', 1.5, 'MarkerSize', 4, ...
    'DisplayName', 'Immediate Jump');

% --- 4. ตกแต่งกราฟ ---
xlabel('Number of Steps');
ylabel('Rotational Velocity (Absolute)');
title('Comparison of Acceleration Only (Constant Velocity Removed)');
legend('show', 'Location', 'best');
axis tight; 

hold off;