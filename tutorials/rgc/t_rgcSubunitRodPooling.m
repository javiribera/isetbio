% t_rgcSubunitRodPooling
% 
% Demonstrates the inner retina object calculation for the subunit RGC
% model (from Gollisch & Meister, 2008, Science; Golisch & Meister, 2010,
% Neuron). 
% 
% Figure 2A of the 2010 Neuron paper shows a simple model of spatial
% pooling for detection sensitivity.  We implement that model here, which
% is only isomerizations, temporal filtering, half wave rectification,
% summation (bipolar).
%
% We explore the properties of that model for different receptor models,
% parameters of the models, simple stimuli, and so forth.  The point of
% this is to get us into the mode of implementing models in the literature
% to try to replicate what is in the papers.
% 
% 3/2016 BW JRG HJ (c) isetbio team

%%
ieInit

%% Movie of the a monochromatic region of rod absorptions (TODO)


% For the moment, we take what's up there which is a bunch of cone
% isomerizations.  We will make a directory for creating rod stimuli as
% well.

% Get data from isetbio archiva server
rd = RdtClient('isetbio');
rd.crp('/resources/data/istim');
a = rd.listArtifacts;

% Pull out .mat data from artifact
whichA =1 ;
data = rd.readArtifact(a(whichA).artifactId);
% iStim stores the scene, oi and cone absorptions
iStim = data.iStim;
absorptions = iStim.absorptions;

% Grating subunit stimulus
% params.barWidth = 24;
% iStim = ieStimulusGratingSubunit;
% absorptions = iStim.absorptions;

% White noise
% iStim = ieStimulusWhiteNoise;

% Show raw stimulus for osIdentity
coneImageActivity(absorptions,'dFlag',true);

%% Photocurrent calculation

% We have the moment by moment absorptions.  We now want to create the
% tempmorally filtered version.  If G&M had given us a temporal impulse
% response for the photoreceptor, we would have used it.  For this
% calculation, we use the ISETBIO default.
os = osCreate('linear');

% Set size of retinal patch
patchSize = sensorGet(absorptions,'width','um');
os = osSet(os, 'patch size', patchSize);

% Set time step of simulation equal to absorptions
timeStep = sensorGet(absorptions,'time interval','sec');
os = osSet(os, 'time step', timeStep);

% Set osI data to raw pixel intensities of stimulus
os = osCompute(os,absorptions);

% Plot the photocurrent for a pixel
% osPlot(os,absorptions);
% 
% Can we make a movie of the photocurrent over time?
%

%% G&M tell us to half-wave rectify the photocurrent response.

% What the hell does that mean?  Where is zero?
% We should write a hwRect function
%
%   out = hwRect(data,val);
%
eZero = -50;
hwrCurrent = ieHwrect(os.coneCurrentSignal,eZero);

%% Then we need a little spatial summation over the cones

% This is like a bipolar cell, but actually it could be the same code as in
% the spatial summation of the RGC
%
%  bipolar = spatialSummation(hwr,params);
%
%  spatialTemporalSummation()
%

kernel = fspecial('gaussian',[9,9],3);

bipolar = ieSpaceTimeFilter(hwrCurrent,kernel);

% For visualization, set the bipolar current to positive
% Not working correctly!  Try to understand how to visualize positive and
% negative numbers.  Maybe voltImageActivity ... that is thought through
% correctly for positive and negative numbers.
% bmosaic = sensorSet(absorptions,'photons',bipolar);
% coneImageActivity(bmosaic,'dFlag',true);

% Not sure if this is detailed enough; not used after this point.
strideSubsample = 4;
bipolarSubsample = ieImageSubsample(bipolar, strideSubsample);

%% Show bipolar activity
vcNewGraphWin;
for frame1 = 1:size(bipolarSubsample,3)
    imagesc(squeeze(bipolarSubsample(:,:,frame1)));
    pause(0.1)
    colormap gray; drawnow;
end
close;

%%
