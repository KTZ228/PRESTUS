
clear
cd /project/3015999.02/andche_sandbox/orca-lab/project/tuSIM/ % change path here

% add paths
addpath('functions')
addpath(genpath('toolboxes')) 
addpath('/home/common/matlab/fieldtrip/qsub') % uncomment if you are using Donders HPC


parameters = load_parameters('sjoerd_config_opt_CTX250-011_64.5mm.yaml')

out_folder = parameters.data_path+'/sim_outputs/';

files = dir(parameters.data_path+'MRI');
subject_list = [];
for i = 1:length(files)
    fname = files(i).name;
    if regexp(fname, 'sub-\d+')
        subject_list = [subject_list str2num(fname(5:7))];
    end
end

parameters.medium = 'layered';
reference_to_transducer_distance = -(parameters.transducer.curv_radius_mm - parameters.transducer.dist_to_plane_mm);
subject_id = 1;

for subject_id = subject_list(subject_list>=7)

subj_folder = fullfile(parameters.data_path, sprintf('%s/sub-%03d/', subject_id));
filename_t1 = dir(sprintf(fullfile(parameters.data_path,parameters.t1_path_template), subject_id));
t1_header = niftiinfo(fullfile(filename_t1.folder,filename_t1.name));
t1_image = niftiread(fullfile(filename_t1.folder,filename_t1.name));

trig_mark_files = dir(sprintf('%s/sub-%03d/Sessions/Session_*/TMSTrigger/TriggerMarkers_Coil0*.xml',parameters.data_path, subject_id));

% sort by datetime
extract_dt = @(x) datetime(x.name(22:end-4),'InputFormat','yyyyMMddHHmmssSSS');
[~,idx] = sort([arrayfun(extract_dt,trig_mark_files)],'descend');
trig_mark_files = trig_mark_files(idx);

[left_trans_ras_pos, left_amygdala_ras_pos] = get_trans_pos_from_trigger_markers(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name), 5, ...
    reference_to_transducer_distance, parameters.expected_focal_distance_mm);
left_trans_pos = ras_to_grid(left_trans_ras_pos, t1_header);
left_amygdala_pos = ras_to_grid(left_amygdala_ras_pos, t1_header);

trig_mark_files = dir(sprintf('%s/sub-%03d/Sessions/Session_*/TMSTrigger/TriggerMarkers_Coil1*.xml',parameters.data_path, subject_id));

% sort by datetime
extract_dt = @(x) datetime(x.name(22:end-4),'InputFormat','yyyyMMddHHmmssSSS');
[~,idx] = sort([arrayfun(extract_dt,trig_mark_files)],'descend');
trig_mark_files = trig_mark_files(idx);

[right_trans_ras_pos, right_amygdala_ras_pos] = get_trans_pos_from_trigger_markers(fullfile(trig_mark_files(1).folder, trig_mark_files(1).name), 5, ...
    reference_to_transducer_distance, parameters.expected_focal_distance_mm);
right_trans_pos = ras_to_grid(right_trans_ras_pos, t1_header);
right_amygdala_pos = ras_to_grid(right_amygdala_ras_pos, t1_header);

imshowpair(plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), left_trans_pos, left_amygdala_pos, parameters), plot_t1_with_transducer(t1_image, t1_header.PixelDimensions(1), right_trans_pos, right_amygdala_pos, parameters),'montage');

transducers = [left_trans_pos right_trans_pos];
targets = [left_amygdala_pos right_amygdala_pos];
target_names = {'left_amygdala', 'right_amygdala'};

target_id = 1;
parameters.transducer.pos_t1_grid = transducers(:,target_id)';
parameters.focus_pos_t1_grid = targets(:,target_id)';
parameters.results_filename_affix = sprintf('_target_%s', target_names{target_id});
parameters.interactive = 0;
single_subject_pipeline(subject_id, parameters)
end