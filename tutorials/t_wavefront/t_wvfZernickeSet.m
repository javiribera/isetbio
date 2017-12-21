function t_wvfZernickeSet
% Illustrate the effects of adjusting Zernicke coefficients on the PSF
%
% Description:
%    Illustrate the effects on the PSF of adjusting different Zernicke
%    polynomial coefficients.
%
%    We create an image of the slanted bar and pass it through the optics.
%
% Notes:
%    * [Note: JNM - Can we please include explanations for why the included
%      default values are chosen, other potential options, or reasonable
%      alternatives for the selections?]
%
% BW Wavefront Toolbox Team, 2014

%% Initialize
ieInit;

%% Create a scene
scene = sceneCreate('slanted bar');

%% Create wavefront object and push it into an optical image object
wvf = wvfCreate;
wvf = wvfComputePSF(wvf);
% wavefront object, plot type, plot units, wavefront list, plot range
wvfPlot(wvf, '2dpsfspace', 'um', 550, 20);
oi = wvf2oi(wvf);

%% Make an ISET optical image
oi = oiCompute(oi, scene);
vcAddObject(oi);
oiWindow;

%% Change the defocus coefficient
wvf = wvfCreate;
D = [0, 0.5, 1];
for ii=1:length(D)
    wvf = wvfSet(wvf, 'zcoeffs', D(ii), {'defocus'});
    wvf = wvfComputePSF(wvf);
    wvfPlot(wvf, '2dpsfspace', 'um', 550, 20);
    oi = wvf2oi(wvf);
    oi = oiCompute(oi, scene);
    oi = oiSet(oi, 'name', sprintf('D %.1f', D(ii)));
    vcAddObject(oi);
    oiWindow;
end

%% Now astigmatism with a little defocus
wvf = wvfCreate;
A = [-0.5, 0, 0.5];
for ii=1:length(A)
    wvf = wvfSet(wvf, 'zcoeffs', [0.5, A(ii)], ...
        {'defocus', 'vertical_astigmatism'});
    wvf = wvfComputePSF(wvf);
    wvfPlot(wvf, '2dpsfspace', 'um', 550, 20);
    oi = wvf2oi(wvf);
    oi = oiCompute(oi, scene);
    oi = oiSet(oi, 'name', sprintf('D %.1f, A %.1f', 0.5, A(ii)));
    vcAddObject(oi);
    oiWindow;
end