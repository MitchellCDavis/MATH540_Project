% 
url = ['https://ftp.sra.ebi.ac.uk/vol1/fastq/' ...
       'ERR227/007/ERR2276797/ERR2276797_1.fastq.gz'];

filename = 'ERR2276797_1.fastq.gz';


%%
projectDir = ...
    'D:\OneDrive\UM\SCHOOL\Math 540\proj\MATH540_Project\E-MTAB-6452';

folders = {
    'data/raw/m6'
    'data/raw/p6'
    'data/raw/m15'
    'data/raw/m30'
    'data/raw/p30'
    'data/raw/m72'
    'data/raw/m120'
    'data/raw/p120'
    'data/trimmed'
    'data/reference'
    'results/qc'
    'results/alignment'
    'results/counts'
    'results/analysis'
    'scripts'
    };

for i = 1:numel(folders)
    mkdir(fullfile(projectDir, folders{i}));
end

cd(projectDir);

%%

rawDir = fullfile(projectDir, 'data', 'raw');

% Experimental metadata
samples = table( ...
    ["m6"; "p6"; "m15"; "m30"; ...
    "p30"; "m72"; "m120"; "p120"], ...
    ["ERR2276800"; "ERR2276804"; ...
    "ERR2276798"; "ERR2276799"; ...
    "ERR2276803"; "ERR2276801"; ...
    "ERR2276797"; "ERR2276802"], ...
    ["starvation"; "control"; ...
    "starvation"; "starvation"; ...
    "control"; "starvation"; ...
    "starvation"; "control"], ...
    [6; 6; 15; 30; 30; 72; 120; 120], ...
    'VariableNames', ...
    {'Sample','Run','Condition','TimeHours'});


%making urls, they have a weird layout
samples.Read1URL = strings(height(samples), 1);
samples.Read2URL = strings(height(samples), 1);

for i = 1:height(samples)

    runID = samples.Run(i);

    prefix = extractBefore(runID, 7);

    suffix = "00" + extractAfter(runID, strlength(runID)-1);

    baseURL =  "https://ftp.sra.ebi.ac.uk/vol1/fastq/" + prefix + "/" + suffix + "/" + runID + "/";

    samples.Read1URL(i) = baseURL + runID + "_1.fastq.gz";
    samples.Read2URL(i) = baseURL + runID + "_2.fastq.gz";

end

disp(samples);




%% Download FASTQ files

for i = 1:height(samples)

    sampleName = char(samples.Sample(i));
    runID = char(samples.Run(i));
    outDir = fullfile(rawDir, sampleName);

    %they should be made but just in case we delete or change smtg
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    urls = [
        samples.Read1URL(i)
        samples.Read2URL(i)
        ];

    for j = 1:2

        filename = sprintf('%s_%d.fastq', runID, j);

        fastqFile = fullfile(outDir, filename);
        gzFile = [fastqFile '.gz'];
        tempFile = [gzFile '.part'];

        % Skip if already downloaded
        if isfile(fastqFile)
            fprintf('Already downloaded: %s\n', filename);
            continue;
        end

        fprintf('\nDownloading %s...\n', filename);

        if isfile(tempFile)
            resumeOption = '-C -';
        else
            resumeOption = '';
        end

        % Download FASTQ (cmd line instead of webdownload)
        cmd = sprintf([ ...
            'curl.exe -L --fail --silent --show-error ' ...
            '--retry 5 --retry-delay 2 %s ' ...
            '--output "%s" "%s"'], ...
            resumeOption, tempFile, urls(j));

        [status, output] = system(cmd);

        if status ~= 0
            error('Download failed: %s\n%s', filename, output);
        end

        fprintf('Download complete. Decompressing...\n');

        movefile(tempFile, gzFile);

        % Decompress
        gunzip(gzFile, outDir);

        % Delete compressed file
        delete(gzFile);

        fprintf('Finished: %s\n', filename);

    end
end

fprintf('\nAll FASTQ files downloaded\n');

%%

system()