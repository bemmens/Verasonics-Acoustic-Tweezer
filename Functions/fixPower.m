function [V,W,N,TTNB,newWave] = fixPower(in,type,state,tP,wave)

    switch type
        case 'V'
            V = in;
            W = state(2);
            N = state(3);
            TTNB = state(4);
            dutyCycle = genDC(wave,TTNB);
            P = 0.5*V;
            transmitPower = 0.5*state(1)*dutyCycle
            k = TTNB*tP/(V*W*N)
    
            W = W*(k^0.5);
            TTNB = TTNB/(k^(0.5));
            if W>1
                W = 1;
                kN = (state(1)/in) * (state(2)/W) * (TTNB/state(4))
                N = 2*round(kN*state(3)/2)
            end
            
            
            newWave = genWvfm([1,W,N,1]);
            dutyCycle = genDC(newWave,TTNB)
            transmitPower = 0.5*V*dutyCycle

        case 'W'
        case 'N'
        case 'TTNB'
    end

end