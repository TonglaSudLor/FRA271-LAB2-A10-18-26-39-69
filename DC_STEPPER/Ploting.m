% --- 1. ดึงข้อมูลและจัดการตัวแปร ---
raw_current = double(squeeze(data{1}.Values.Data));
raw_duty = double(squeeze(data{5}.Values.Data));

% แปลงหน่วย Duty Cycle (0-100%)
duty_percent = (raw_duty / 65535) * 100;

% --- 2. เรียงลำดับข้อมูล (สำคัญมากก่อนกรอง) ---
[duty_sorted, sort_idx] = sort(duty_percent);
current_sorted = raw_current(sort_idx);

% --- 3. กรองข้อมูลแบบ Robust (ขจัดค่าแหลมแบบขั้นสูง) ---
% ใช้ 'rlowess' : เป็นวิธีที่เก่งที่สุดในการกำจัด Outlier โดยยังรักษาทรงกราฟเดิมไว้
% ปรับเลข 200 ได้ครับ (ยิ่งเยอะยิ่งเรียบ แต่ถ้าเยอะไปกราฟจะเริ่มเบี้ยว)
% แนะนำช่วง 100 - 500 สำหรับข้อมูลเยอะๆ
current_clean = smoothdata(current_sorted, 'rlowess', 300); 

% --- 4. พล็อตกราฟ (เอาแค่เส้นที่กรองแล้ว) ---
figure('Name', 'Motor Current Cleaned', 'Color', 'w');
grid on; hold on;

% พล็อตเส้นเดียวเลย เน้นๆ
plot(duty_sorted, current_clean, 'b-', 'LineWidth', 2);

% --- 5. ตกแต่งกราฟ ---
xlabel('PWM Duty Cycle (%)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Motor Current (A)', 'FontSize', 12, 'FontWeight', 'bold');
title('Motor Current vs PWM Duty (Cleaned)', 'FontSize', 14);

xlim([0 100]);
ylim([0 max(current_clean)*1.1]);

hold off;