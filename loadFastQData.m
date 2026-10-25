function [fastqDataStruct] = loadFastQData(filepath)

fastqDataStruct = fastqread(filepath);
return;

end