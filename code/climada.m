function measures_impact=climada(entity_today_file,entity_future_file,hazard_today_file,hazard_future_file,check_plots)
% climada all in one adaptaton cost curve climate scenarios economic grwoth projection
% MODULE:
%   core
% NAME:
%   climada
% PURPOSE:
%   Import entity today and entity future, ask for corresponding hazard
%   event sets, show a few plots for checks, run all calculations and
%   produce the final adaptation cost curve - all in one call.
%
%   Special: on subsequent calls, the routine suggest last inputs - and if
%   the first file selection is the same as on previous call, even asks to
%   re-run with previous call's inputs without asking for each's
%   confirmation.
%   It further checks for the entity file to have been edited since last
%   call. If not, it does not ask for plotting assets and damagefunctions
%   again. If one wants to plot, needs to either save the entity again or
%   select another file and then cancel.
%
%   Programmes's note: The present code mainly handles asdmin, i.e.
%   checking files, while all calculations are run be the core climada
%   functions, i.e. climada_entity_read, climada_measures_impact, 
%   climada_adaptation_event_view and - last but not least -
%   climada_adaptation_cost_curve. 
% CALLING SEQUENCE:
%   measures_impact=climada(entity,entitiy_future,hazard_today_file,hazard_future_file)
% EXAMPLE:
%   measures_impact=climada % all prompted for
% INPUTS:
%   entity_today_file: entity (assets, damagefunctions and measures) today
%       a climada entity structure (see climada_entity_read)
%       > prompted for if empty
%   entity_future_file: future entity (assets, damagefunctions and measures) to
%       represent projected economic growth, a climada entity structure
%       (see climada_entity_read)
%       > prompted for if empty
%   hazard_today_file: a climada hazard event set for today
%       > promted for if not given
%   hazard_future_file: a climada hazard event set for future (climate scenario)
%       > promted for if not given
% OPTIONAL INPUT PARAMETERS:
%   check_plots: whether we show a few check plots (assets,
%       damagefunctions)
%       =0: no plots (default)
%       =1: show plots
%       The code also switches to ask for plotthis if it needs to prompt
%       for filenames, i.e. operates in interactive mode.
% OUTPUTS:
%   measures_impact: the same output as climada_measures_impact
%   and plots: adaptation cost curve, adaptation event view
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20150101, initial
%-

measures_impact=[]; % init output

% keep filenames for subsequent calls (as one might edit the entity files
% and wants to re-calculate) and suggest them in GUIs
persistent entity_today_file_def
persistent entity_future_file_def
persistent hazard_today_file_def
persistent hazard_future_file_def
persistent entity_today_file_last_date

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('entity_today_file','var'), entity_today_file ='';end
if ~exist('entity_future_file','var'),entity_future_file='';end
if ~exist('hazard_today_file','var'), hazard_today_file ='';end
if ~exist('hazard_future_file','var'),hazard_future_file='';end
if ~exist('check_plots','var'),       check_plots       =0;end

% PARAMETERS
%
% whether we ask the user about plotting assets and damage functions
% if not all inputs parameters are provided, i.e. we prompt for filenames,
% we also will show the questdlg (see code).
show_questdlg=0; % default=0

% prompt for entity_today_file if not given
if isempty(entity_today_file) % local GUI
    show_questdlg=1;
    if isempty(entity_today_file_def)
        entity_today_file=[climada_global.data_dir filesep 'entities' filesep '*' climada_global.spreadsheet_ext];
    else
        entity_today_file=entity_today_file_def;
    end
    [filename, pathname] = uigetfile(entity_today_file, 'Select entity today:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_today_file=fullfile(pathname,filename);
        if strcmp(entity_today_file,entity_today_file_def)
            ButtonName=questdlg('Would you like to use all parameters from last call?','File dialogs','Yes','No','Yes');
            if strcmp(ButtonName,'Yes')
                % use all parameters as in last call
                entity_today_file =entity_today_file_def;
                entity_future_file=entity_future_file_def;
                hazard_today_file =hazard_today_file_def;
                hazard_future_file=hazard_future_file_def;
                check_plots=0;
                show_questdlg=0;
            end
        else
            entity_today_file_def=entity_today_file;
        end
    end
end

% prompt for hazard_today_file if not given
if isempty(hazard_today_file) % local GUI
    show_questdlg=1;
    if isempty(hazard_today_file_def)
        hazard_today_file=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    else
        hazard_today_file=hazard_today_file_def;
    end
    [filename, pathname] = uigetfile(hazard_today_file, 'Select hazard set today:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_today_file=fullfile(pathname,filename);
        hazard_today_file_def=hazard_today_file;
    end
end

% prompt for entity_future_file if not given
if isempty(entity_future_file) % local GUI
    show_questdlg=1;
    if isempty(entity_future_file_def)
        entity_future_file=[climada_global.data_dir filesep 'entities' filesep '*' climada_global.spreadsheet_ext];
    else
        entity_future_file=entity_future_file_def;
        
    end
    [filename, pathname] = uigetfile(entity_future_file, 'Select entity future:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_future_file=fullfile(pathname,filename);
        entity_future_file_def=entity_future_file;
    end
end

% prompt for hazard_future_file if not given
if isempty(hazard_future_file) % local GUI
    show_questdlg=1;
    if isempty(hazard_future_file_def)
        hazard_future_file=[climada_global.data_dir filesep 'hazards' filesep '*.mat'];
    else
        hazard_future_file=hazard_future_file_def;
    end
    [filename, pathname] = uigetfile(hazard_future_file, 'Select future hazard set:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_future_file=fullfile(pathname,filename);
        hazard_future_file_def=hazard_future_file;
    end
end

% check for the entity file to have been edited since last call
% if not, do not ask for plotting assets and damagefunctions again
% if one wants to plot, needs to either save the entity again or select
% another file and then cancel.
[fP,fN,fE]=fileparts(entity_today_file);
fN=[fN fE];
D=dir(fP);
for D_i=1:length(D)
    if strcmp(D(D_i).name,fN)
        if isempty(entity_today_file_last_date)
            entity_today_file_last_date=D(D_i).datenum;
        else
            if D(D_i).datenum-entity_today_file_last_date==0
                % same entity, not edited, hence no need to show plots again
                check_plots=0;
                show_questdlg=0;
            end
        end
    end
end % D_i

if show_questdlg
    ButtonName=questdlg('Would you like to see check plots (assets, damagefunctions) ?','Check plot dialog','Yes','No','Yes');
    if strcmp(ButtonName,'Yes'),check_plots=1;end
end

if exist(hazard_today_file,'file')
    load(hazard_today_file) % contains hazard
else
    fprintf('Error: hazard today not found (%s)\n',hazard_today_file)
    return
end
entity_today=climada_entity_read(entity_today_file,hazard); % contains entity

if check_plots
    figure('Name','entity assets today');
    if ~climada_global.octave_mode
        % entity plot with pcolor takes (far) too long in Octave
        climada_entity_plot(entity_today);
    else
        climada_circle_plot(entity_today.assets.Value,...
            entity_today.assets.Longitude,entity_today.assets.Latitude)
    end
    figure;climada_damagefunctions_plot(entity_today,hazard.peril_ID);
end % check_plots

% before calling climada_measures_impact, force re-encoding by removing
% hazard from entity.assets
entity_today.assets=rmfield(entity_today.assets,'hazard');
% calculate today's measures impact, for reference
measures_impact_today=climada_measures_impact(entity_today,hazard,'no');

clear entity % redundant, to be on the safe side
clear hazard % redundant, to be on the safe side

if exist(hazard_future_file,'file')
    load(hazard_future_file) % contains hazard, overwrites hazard today
else
    fprintf('Error: hazard future not found (%s)\n',hazard_future_file)
    return
end
entity_future=climada_entity_read(entity_today_file,hazard); % hazard contains future hazard

if check_plots
    % later, show delta assets
    
end % check_plots

% before calling climada_measures_impact, force re-encoding by removing
% hazard from entity.assets
entity_future.assets=rmfield(entity_future.assets,'hazard');
% calculate future measures impact, discount to today - the final calculation
measures_impact=climada_measures_impact(entity_future,hazard,measures_impact_today); % hazard contains future hazard

% show adaptation cost curve and event view
figure('Name','adaptation event view');climada_adaptation_event_view(measures_impact); % 2nd last to
figure('Name','adaptation cost curve');climada_adaptation_cost_curve(measures_impact); % to be best visible

end
