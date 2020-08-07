% Script written manually (01-Aug-2020)
%% SECTION0: variables
dataloc = '/data/MEG/Projects/spendl/Spendl_FTimport_SKevoked/data';
scriptloc = '/data/MEG/Projects/spendl/spendl_SK_scripts';
subject = {'1798', '2233', '2347', '2516', '3214', '3335', '3337', '3419', '3621', '3663', '3800', '4199', '4301', '4325', '4410', '4670', '4803', '4832', '5051', '5146'};
clozes = {'cloze1', 'cloze2', 'cloze3', 'cloze4', 'cloze5'};
condition = {'all', 'Expec', 'Unexpec', 'Anam', 'Pseudo', 'Word'};
%subject2 = {'5146'}

cd(dataloc)
%% SECTION1: Delete the existing source files (done)
% for i=1:length(subject)
%     subj_folder=fullfile(dataloc, subject{i});
%     cd(subj_folder)
%     for j=1:length(condition)
%         cond=condition{j};
%         folder_by_cond=[];
%         cd(subj_folder)
%         out=dir(['*',cond,'*']);
%         disp(length(out))
%         folder_by_cond={out(:).name};
%         disp(folder_by_cond)
%         
%         for k=1:length(folder_by_cond)
%             cd(strcat(subj_folder, '/', char(folder_by_cond(k))))
%             out2=dir('results_MN_MEG_GRAD_*.mat')
%             file=char({out2(:).name});
%             if exist(file, 'file')==2
%                 delete(file);
%             end
%         end
%     end
% end
% db_reload_database('current',1)
% return;

%% SECTION2: Create sFiles (average files, which are input to Compute Source 2018)
% sFiles = {...
%     '1798/cloze1_1798_Anam_IC_data/data_cloze1_1798_Anam_IC_average_200720_1531.mat', ...
%     '1798/cloze2_1798_Anam_IC_data/data_cloze2_1798_Anam_IC_average_200720_1531.mat'};

sFiles={}
for i=1:length(subject)
    subj_folder=fullfile(dataloc, subject{i});
    cd(subj_folder)
    for j=1:length(condition)
        cond=condition{j};
        folder_by_cond=[];
        cd(subj_folder)
        out=dir(['*',cond,'*']);
        folder_by_cond={out(:).name};
        if length(folder_by_cond)~=5
            fprintf('%s , condition %s does not have 5 folders.', subj_folder(end-3:end), cond)
            in1=input('Proceed (y/n)?','s')
            if strcmpi(in1, 'n')
                break;
            end
        end
        for k=1:length(folder_by_cond)
            cond_folder=strcat(subj_folder, '/', char(folder_by_cond{k}));
            cd(cond_folder)
            out3=dir(['data_','*', cond,'_IC_average_','*','.mat']);
            avgfile={out3(:).name};
            if length(avgfile)~=1
                fprintf('%s does not have 1 average file.', folder_by_cond{k})
                ip2=input('Proceed (y/n)?','s')
                if strcmpi(ip2,'n')
                    break;
                end
            end
            sFiles{end+1}=strcat(subject{i},'/',char(folder_by_cond{k}),'/',char(avgfile));
        end
    end
        
end

disp(sFiles)
%return;
%% SECTION3: compute source [2018]

% Start a new report
bst_report('Start', sFiles);

db_reload_database('current',1)

% Process: Compute sources [2018]
sFiles = bst_process('CallProcess', 'process_inverse_2018', sFiles, [], ...
    'output',  2, ...  % Kernel only: one per file
    'inverse', struct(...
         'Comment',        'MN: MEG ALL', ...
         'InverseMethod',  'minnorm', ...
         'InverseMeasure', 'amplitude', ...
         'SourceOrient',   {{'fixed'}}, ...
         'Loose',          0.2, ...
         'UseDepth',       1, ...
         'WeightExp',      0.5, ...
         'WeightLimit',    10, ...
         'NoiseMethod',    'reg', ...
         'NoiseReg',       0.1, ...
         'SnrMethod',      'fixed', ...
         'SnrRms',         1e-06, ...
         'SnrFixed',       3, ...
         'ComputeKernel',  1, ...
         'DataTypes',      {{'MEG GRAD', 'MEG MAG'}}));

% Save and display report
ReportFile = bst_report('Save', sFiles);
bst_report('Open', ReportFile);
% bst_report('Export', ReportFile, ExportDir);

disp('Source Computation finished.')
return;

%% SECTION4: make an average of ~5 source maps across cloze runs

%db_reload_database('current',1)

for i=1:length(subject)
    subj_folder=fullfile(dataloc, subject{i});
    cd(subj_folder)
    for j=1:length(condition)
        cond=condition{j};
        folder_by_cond=[];
        out=dir(['*',cond,'*']);
        %disp(length(out))
        folder_by_cond={out(:).name};
        disp(folder_by_cond)
        if length(folder_by_cond)~=5
            fprintf('%s , condition %s does not have 5 folders.', subj_folder(end-3:end), cond)
            a=input('Does the folder look okay (y/n)?','s')
            if strcmpi(a,'n')
                break;
            end
        end
        sFiles={}        
        for k=1:length(folder_by_cond)
            cd(strcat(subj_folder, '/', char(folder_by_cond(k))))
            out3=dir('results_MN_MEG_GRAD_*_20080*.mat')
            sourcefile={out3(:).name};
            if length(sourcefile)~=1
                disp(folder_by_cond{k})
                b=input('Check the # of results_mat file. Proceed (y/n)?','s')
                if strcmpi(b,'n')
                    break;
                end
            end
            sFiles{end+1}=strcat(subject{i},'/',char(folder_by_cond{k}),'/',char(sourcefile));
            disp(sFiles)
        end

        % Start a new report
        bst_report('Start', sFiles);
        
        % Process: Weighted Average: Everything
        sFiles = bst_process('CallProcess', 'process_average', sFiles, [], ...
            'avgtype',         1, ...  % Everything
            'avg_func',        1, ...  % Arithmetic average:  mean(x)
            'weighted',        1, ...
            'scalenormalized', 0);

        % Save and display report
        ReportFile = bst_report('Save', sFiles);
        bst_report('Open', ReportFile);
        % bst_report('Export', ReportFile, ExportDir);   
        cd(subj_folder)
    end
end

%% Delete condition average file from subj/@intra

% for i=1:length(subject)
%     subj_folder=fullfile(dataloc, subject{i});
%     intra_loc = strcat(subj_folder, '/', '@intra')
%     cd(intra_loc)
%     
%     out3=dir('results_average_20080*.mat')
%     if length(out3)~=6
%         disp(intra_loc)
%         c=input('Check the # of results_average.mat file. Proceed (y/n)?','s')
%         if strcmpi(c,'n')
%             break;
%         end
%     end
%     for j=1:length(out3)
%         avgfile=out3(j).name
%         if exist(avgfile, 'file')==2
%             delete(avgfile);
%         end
%     end
% end


%% section5: z-score

for i=1:length(subject)
    subj_folder=fullfile(dataloc, subject{i})
    intra_loc = strcat(subj_folder, '/', '@intra')
    cd(intra_loc)
    
    out4=dir('results_average_200806_*.mat')
    if length(out4)~=6
        disp(intra_loc)
        c=input('Check the # of results_average.mat file. Proceed (y/n)?','s')
        if strcmpi(c,'n')
            break;
        end
    end
    sFiles={}
    for j=1:length(out4)
        avgfile=out4(j).name
        sFiles{end+1}=strcat(intra_loc,'/',avgfile);        
    end
    
    % Start a new report
    bst_report('Start', sFiles);

    % Process: Z-score transformation: [-200ms,-1ms]
    sFiles = bst_process('CallProcess', 'process_baseline_norm', sFiles, [], ...
    'baseline',   [-0.2, -0.001], ...
    'source_abs', 0, ...
    'method',     'zscore', ...  % Z-score transformation:    x_std = (x - &mu;) / &sigma;
    'overwrite',  0);

    % Save and display report
    ReportFile = bst_report('Save', sFiles);
    bst_report('Open', ReportFile);
    % bst_report('Export', ReportFile, ExportDir)    
end



%% section6: previous attempt
% for i=1:length(subject)
%     for j=1:length(condition)
%         disp(condition{j})
%         subj_folder = fullfile(dataloc, subject{i});
%         cd(subj_folder);
%         condition_folder=[];
%         pathToScript = fullfile(scriptloc,'get_cond_folders.sh');
%         system(pathToScript);
%         command1 = sprintf('find . -type d -name "*%s*"', condition{j});
%         command2 = strcat('store=($(', command1, '))');
%         command3 = sprintf('store=($(find . -type d -name "*%s*"))', condition{j})
%         command_test = 'store=($(find . -type d -name "*all*"))'
%         store=($(find . -type d -name "*all*"))
%         disp(command2)
%         !store=($(find . -type d -name "*${c}*"))
%         test='find . -type d -name "cloze1*"';      
%         [status, cmdout]=unix(command1)
%         disp(cmdout)
%         
%         for k=1:length(cmdout)
%             cd cmdout[k];
%             !file=($(find . -name "results_MN_MEG_GRAD*"))
%             if length(file) > 1
%                 disp (subject{1}, length(file))
%                 break;
%             end
%             condition_folder=[condition_folder; file]
%             del file
%         if length(condition_folder)~=5
%             disp('check the folder')            
%         end
%         sFiles = bst_process('CallProcess', 'process_inverse_2018', condition_folder, [], ...
%         'output',  2, ...  % Kernel only: one per file
%         'inverse', struct(...
%              'Comment',        'MN: MEG ALL', ...
%              'InverseMethod',  'minnorm', ...
%              'InverseMeasure', 'amplitude', ...
%              'SourceOrient',   {{'fixed'}}, ...
%              'Loose',          0.2, ...
%              'UseDepth',       1, ...
%              'WeightExp',      0.5, ...
%              'WeightLimit',    10, ...
%              'NoiseMethod',    'diag', ...
%              'NoiseReg',       0.1, ...
%              'SnrMethod',      'fixed', ...
%              'SnrRms',         1e-06, ...
%              'SnrFixed',       3, ...
%              'ComputeKernel',  1, ...
%              'DataTypes',      {{'MEG GRAD', 'MEG MAG'}}));
%         disp(sFiles)
%         del condition_folder
%         end
%     end
% end


