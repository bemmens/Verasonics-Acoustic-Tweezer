function rP = BeamPattern(D,lambda)
%Generates relangleative beam preassure between -pi/2 and pi/2 as a
%function of wavelength (lambda) and element diameter(D) both in meters.
%D = 3e-3;
%lambda = 1481/1e6;
%assumes circular piston

phi = linspace(-pi/2,pi/2,101);
arg = pi*(D/lambda).*sin(phi);
rP = ((2*besselj(1,arg))./(arg)).^2;

%plot(phi,rP)
end