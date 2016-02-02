function entity=climada_entity_load(entity)
% climada
% NAME:
%   climada_entity_load
% PURPOSE:
%   load a previously saved entity (just to avoid typing long paths and
%   filenames in the command window)
% CALLING SEQUENCE:
%   entity_out=climada_entity_load(entity)
% EXAMPLE:
%   entity=climada_entity_load('demo_today')
% INPUTS:
%   hazard: the filename (and path, optional) of a previously saved entity
%       structure. If no path provided, default path ../data/entities is used
%       (and name can be without extension .mat)
%       > promted for if empty
%       OR: an entity structure, in which cas it is just returned (to allow
%       calling climada_entity_load anytime, see e.g. climada_EDS_calc)
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   entity_out: a struct, see e.g. climada_assets_read for details
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20091230
% David N. Bresch, david.bresch@gmail.com, 20150804, allow for name without path on input
% David N. Bresch, david.bresch@gmail.com, 20150820, memory use optimized, filename checked
% Lea Mueller, muellele@gmail.com, 20151124, check that field .assets exist
% Lea Mueller, muellele@gmail.com, 20151127, enhance to work with complete entity as input
% Lea Mueller, muellele@gmail.com, 20151127, set entity_file to empty if a struct without .assets
% David N. Bresch, david.bresch@gmail.com, 20160202, speedup if entity structure passed
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end

% PARAMETERS

% if already a complete hazard, return
if isstruct(entity)
    return % already a hazard
else
    entity_file=entity;entity=[];
    % from now on, entity_file is the input and entity will be output
end

% prompt for entity_file if not given
if isempty(entity_file) % local GUI
    entity_file=[climada_global.data_dir filesep 'entities' filesep '*.mat'];
    [filename, pathname] = uigetfile(entity_file, 'Select entity to open:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file=fullfile(pathname,filename);
    end
end

% complete path, if missing
[fP,fN,fE]=fileparts(entity_file);
if isempty(fP),fP=[climada_global.data_dir filesep 'entities'];end
if isempty(fE),fE='.mat';end
entity_file=[fP filesep fN fE];

if ~exist(entity_file,'file')
    fprintf('ERROR: entity does not exist %s\n',entity_file);
    return
else
    load(entity_file); % contains entity, the only line that really matters ;-)
end

% check for valid/correct entity.assets.filename
if isfield(entity,'assets')
    if ~strcmp(entity_file,entity.assets.filename)
        entity.assets.filename=entity_file;
        entity.damagefunctions.filename=entity_file;
        entity.measures.filename=entity_file;
        entity.discount.filename=entity_file;
        save(entity_file,'entity')
    end
end

end % climada_entity_load