function mpd = dpi2mperdot(dpi, unit)
% Convert dots per inch to meters format
%
% Syntax:
%   mpd = dpi2mperdot(dpi, [unit])
%
% Description:
%    Both dpi and microns are commonly used to specify display pixel size.
%    We make it easy to convert from dots per inch to microns per dot.
%
% Inputs:
%    dpi  - Dots per inch
%    unit - (Optional) Unit to convert to. Default is micrometers (um).
%
% Outputs:
%    mpd  - Meter-based units per dot. (Microns unless otherwise specified)
%
% Notes:
%    * [Note: JNM - The ~isempty(dpi) throws an error when no dpi is
%      provided, contrary to the expected behavior of going to the else
%      statement (and an empty return). Does this need to be addressed?]
%
% See Also:
%    mperdot2dpi
%

% Examples:
%{
    dpi = 120;
    mpd = dpi2mperdot(dpi, 'um')
    mpd = dpi2mperdot(dpi)
    mpd = dpi2mperdot(dpi, 'meters')
%}

if notDefined('unit'), unit = 'um'; end

% (X dot/inch * inch/micron )^-1 yields microns/dot. 2.54*1e4 microns/inch
% and (1/(2.54*1e4)) inch/micron. So, dpi * inch/micron yields dots per
% micron. Invert that for microns per dot
if ~isempty(dpi)
    mpd = 1 / (dpi * (1 / (2.54 * 1e4)));
else
    mpd = [];
end

% Put the value in meters and then scale according to the requested unit
mpd = mpd * 10 ^ -6;  % Meters per dot
mpd = mpd * ieUnitScaleFactor(unit);

end