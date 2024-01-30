function dutyCycle = genDC(wave,TTNB)
    onTime = sum(abs(wave)).*4e-3; % us
    %offTime = TTNB-onTime;
    dutyCycle = onTime./TTNB; % including non-pulse time
end