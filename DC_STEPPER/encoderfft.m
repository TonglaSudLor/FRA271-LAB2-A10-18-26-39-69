%% Analyze DC Motor Speed + Design Lowpass + Bode Plot (For a1-a5)
clearvars -except a1 a2 a3 a4 a5; 
clc; close all;

%% ====== CONFIG: ตั้งค่า Filter ตรงนี้ ======
Fp    = 5;        % Passband edge frequency (Hz) - ความถี่ที่ต้องการเก็บ
Fst   = 10;       % Stopband edge frequency (Hz) - ความถี่ที่จะเริ่มตัด
Apass = 0.5;      % Passband ripple (dB)
Astop = 40;       % Stopband attenuation (dB)
Target_Data = 1;  % เลือกข้อมูลดิบจาก {1} หรือ {3} (ปกติ {1} คือ Raw)
%% ==========================================

% รวบรวมข้อมูล
data_list = {a1, a2, a3, a4, a5};
pwm_freqs = [13107, 26214, 39321, 52428, 65535];

% สร้างหน้าต่างกราฟ
f_main = figure('Name', 'Filter Design & Analysis', 'Color', 'k');
f_main.Position = [50 50 1200 800]; % จอใหญ่หน่อยเพราะกราฟเยอะ

% สร้างกลุ่ม Tab
tabGroup = uitabgroup(f_main);

for i = 1:5
    % สร้าง Tab
    t_tab = uitab(tabGroup, 'Title', ['PWM: ' num2str(pwm_freqs(i))]);
    p = uipanel('Parent', t_tab, 'BorderType', 'none', 'BackgroundColor', 'k');
    
    %% 1) โหลดข้อมูล (Load Data)
    try
        ts = data_list{i}{Target_Data}.Values;
        t = ts.Time;
        w = squeeze(ts.Data);
        if size(w,2) > 1, w = w(:,1); end
        
        t = t(:);
        w = w(:);
    catch
        text(0.5, 0.5, 'Error loading data', 'Parent', axes('Parent',p));
        continue;
    end
    
    %% 2) คำนวณ Fs และเตรียม FFT (Raw)
    dt = mean(diff(t));
    Fs = 1/dt; 
    
    N   = length(w);
    win = hann(N);
    
    % FFT ของสัญญาณดิบ
    xw  = (w - mean(w)) .* win;
    Nfft = 2^nextpow2(N);
    X    = fft(xw, Nfft);
    f_axis = (0:(Nfft/2))*(Fs/Nfft);
    magW = abs(X(1:Nfft/2+1))*2/sum(win);

    %% 3) ออกแบบ Lowpass Filter (Design Filter)
    % ใช้ค่า Fs ที่คำนวณได้จริงจากข้อมูลชุดนั้นๆ
    try
        d = designfilt('lowpassiir', ...
            'PassbandFrequency',Fp, ...
            'StopbandFrequency',Fst, ...
            'PassbandRipple',Apass, ...
            'StopbandAttenuation',Astop, ...
            'DesignMethod','butter', ...
            'SampleRate',Fs);
    catch
        warning('Sampling rate too low for these filter specs at PWM index %d', i);
        continue;
    end

    %% 4) กรองสัญญาณ (Apply Filter)
    % ใช้ filtfilt เพื่อลด phase lag (Zero-phase filtering)
    w_filt = filtfilt(d, w);
    
    %% 5) FFT ของสัญญาณหลังกรอง (Filtered FFT)
    xw2  = (w_filt - mean(w_filt)) .* win;
    X2   = fft(xw2, Nfft);
    magF = abs(X2(1:Nfft/2+1))*2/sum(win);
    
    %% 6) คำนวณ Bode ของ Filter (Get Filter Response)
    [H, wHz] = freqz(d, 4096, Fs);
    magdB    = 20*log10(abs(H));
    phaseDeg = unwrap(angle(H))*180/pi;

    %% ====== PLOTTING (จัดวาง 4 กราฟ) ======
    
    % --- Top Left: Time Domain ---
    ax1 = subplot(2, 2, 1, 'Parent', p);
    plot(ax1, t, w, 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5); hold(ax1, 'on');
    plot(ax1, t, w_filt, 'Color', [0 0.45 0.74], 'LineWidth', 1.5);
    grid(ax1, 'on');
    ylabel(ax1, 'Speed');
    xlabel(ax1, 'Time (s)');
    legend(ax1, 'Raw', 'Filtered', 'Location', 'best');
    title(ax1, '1. Time Domain Comparison');
    
    % --- Top Right: FFT Comparison ---
    ax2 = subplot(2, 2, 2, 'Parent', p);
    plot(ax2, f_axis, magW, 'Color', [0.8 0.8 0.8], 'LineWidth', 1); hold(ax2, 'on');
    plot(ax2, f_axis, magF, 'Color', [0.85 0.33 0.1], 'LineWidth', 1.5);
    grid(ax2, 'on');
    xlim(ax2, [0 30]); % ซูมดูช่วง 0-30Hz ตามโค้ดต้นฉบับ
    ylabel(ax2, 'Amplitude');
    xlabel(ax2, 'Frequency (Hz)');
    legend(ax2, 'Raw FFT', 'Filtered FFT');
    title(ax2, '2. FFT Comparison');
    
    % --- Bottom Left: Bode Magnitude ---
    ax3 = subplot(2, 2, 3, 'Parent', p);
    semilogx(ax3, wHz, magdB, 'LineWidth', 1.5, 'Color', [0.47 0.67 0.19]);
    grid(ax3, 'on');
    xlabel(ax3, 'Frequency (Hz)');
    ylabel(ax3, 'Magnitude (dB)');
    title(ax3, '3. Filter Bode Magnitude');
    ylim(ax3, [-100 10]); % จัดช่วงแกน Y ให้สวยงาม
    xline(ax3, Fp, '--k', ['Pass ' num2str(Fp) 'Hz']);
    
    % --- Bottom Right: Bode Phase ---
    ax4 = subplot(2, 2, 4, 'Parent', p);
    semilogx(ax4, wHz, phaseDeg, 'LineWidth', 1.5, 'Color', [0.49 0.18 0.56]);
    grid(ax4, 'on');
    xlabel(ax4, 'Frequency (Hz)');
    ylabel(ax4, 'Phase (deg)');
    title(ax4, '4. Filter Bode Phase');
    
    % Link แกน X ของกราฟ Bode เข้าด้วยกัน
    linkaxes([ax3, ax4], 'x');
end