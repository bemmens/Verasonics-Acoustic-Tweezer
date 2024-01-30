function TX = genTXMove_TEst(currentLoc,nextLoc)
    
    %Specify largest steering step
    load Trans_Ring
    Resouce.Parameters.speedOfSound = 1481;
    wavelength = Resouce.Parameters.speedOfSound/(Trans.frequency*1e6);
    
    dr = wavelength/10;
    if dr>wavelength/2
        disp('ERROR:dr too large!')
        DISP('-------------------')
    end
    
    H = 0.04;
    r0 = currentLoc; %mm
    rTarget = nextLoc; % mm
    
    distance = (rTarget - r0)/1e3 ;%now to m
    nLargestSteps = floor(distance/dr);
    N = nLargestSteps+1;
    %drPrecisionStep = distance-(dr*nLargestSteps);
    %drTotal = nLargestSteps*dr + drPrecisionStep;
    
    %Specify list of positions to move through
        % Includes r0 position (could be removed if move needs to be faster).
    rs = dr*(0:N) + (r0/1000);
    rs(N+1) = rTarget/1000;% x coords of 1st to last position
    thetasMove = pi/2 - cart2pol(rs,H);
    
    naMove = length(thetasMove);
    TX = repmat(struct('waveform', 1, ...
                       'Origin', zeros(1,3), ...
                       'focus', 0, ...
                       'Steer', [0.0,0.0], ...
                       'Apod', ones(1,Trans.numelements), ...
                       'Delay', zeros(1,Trans.numelements)),...
                       1,2*naMove); % matrix shape  
    
    [RH_VortexDelay,DelayMatrix] = compDelayVortex(Trans.ElementPos,0);
    LH_VortexDelay = flip(RH_VortexDelay);
    
    for j = 1:naMove
        TX(j).Steer = [thetasMove(j),0];
        TX(j).Delay = RH_VortexDelay'; 
    end
    for j = naMove+1:(2*naMove)
        TX(j).Steer = [thetasMove(j-naMove),0];
        TX(j).Delay = LH_VortexDelay'; 
    end
    
end