function rP = BeamPattern(D,lambda)
%Generates relative beam preassure between -pi/2 and pi/2 as a
%function of wavelength (lambda) and element diameter(D) for a circular piston in an infinite baffle.
%D = 3e-3;
%lambda = 1481/1e6;

phi = linspace(-pi/2,pi/2,101);
arg = pi*(D/lambda).*sin(phi);
rP = ((2*besselj(1,arg))./(arg)).^2;

%plot(phi,rP)
end