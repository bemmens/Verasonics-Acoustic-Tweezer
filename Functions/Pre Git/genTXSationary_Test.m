function TX = genTXSationary_Test(rmin,rmax,N)
    
    %rmin = -30; % mm
    %rmax = 30;
    H = evalin('base','H'); % m
    rs = linspace(rmin,rmax,N)*1e-3;%radial loc in m
    thetas = pi/2 - cart2pol(rs,H); % steering angles in rad
    naStationary = length(thetas);
    Trans.numelements = evalin('base','Trans.numelements');
    Trans.ElementPos = evalin('base','Trans.ElementPos');
    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,2*naStationary); % matrix shape  
    [RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
    LH_VortexDelay = flip(RH_VortexDelay);
    for j = 1:naStationary
        TX(j).Steer = [thetas(j),0];
        TX(j).Delay = RH_VortexDelay'; 
    end
    for j = naStationary+1:(2*naStationary)
        TX(j).Steer = [thetas(j-naStationary),0];
        TX(j).Delay = LH_VortexDelay'; 
    end

end