classdef SmallWebKBTable < TextReader
%% class for automatically printing the small WebKB table in
%  ECML 2012.
%  This was never used, and the table was manually typed.
%  so this code may not produce a correct table.
    
properties (Constant)
    CSSL = 3;
    AM = 2;
    MAD = 1;
end
    
methods (Static)

%% createWebKBTable
     
function createWebKBTable( outputFileNamePrefix )
    opt_PRBEP = [0.85428     0.60815     0.46296     0.78437;
                 0.8101      0.59947     0.42628     0.74478;
                 0.85479     0.58924     0.41442     0.76182].';
    opt_M_ACC = [0.85448     0.60914     0.46015     0.78547;
                 0.79452      0.5811     0.39114     0.67955;
                 0.78056     0.53631     0.31394     0.56355].';
    opt_PRBEP = opt_PRBEP * 100;
    opt_M_ACC = opt_M_ACC * 100;
%         mean_PRBEP = mean(opt_PRBEP);

    outputFileName = [outputFileNamePrefix '.webkb.tex'];
    outputFile  = fopen(outputFileName, 'a+');

    fprintf(outputFile, '/\begin{table}\n');
    fprintf(outputFile, '\\centering\n');
    fprintf(outputFile, '\\begin{tabular}{ | c | c | c | c | c | }\n');
    fprintf(outputFile, '\\hline\n');
    fprintf(outputFile, '\\multicolumn{2}{|c||}{}  & MAD & MP & \\algorithmName } \\\\\n');
    fprintf(outputFile, '\\hline\n');

    lineFormat = ['~%s~    & ~%s~  & ~%s~ & ~%s~ & ~%s~ & ~%s~ \\\\ \\hline\n'];

    COURSE = 1; FACULTY = 2; PROJECT = 3; STUDENT = 4;

    sourceTable = opt_PRBEP;
    this.printWebKBLine(outputFile, lineFormat, [], 'course', sourceTable(COURSE,:));
    this.printWebKBLine(outputFile, lineFormat, [], 'faculty', sourceTable(FACULTY,:));
    this.printWebKBLine(outputFile, lineFormat, [], 'project', sourceTable(PROJECT,:));
    this.printWebKBLine(outputFile, lineFormat, [], 'student', sourceTable(STUDENT,:));

    fprintf(outputFile, '\\hline\n');
    fprintf(outputFile, '\\end{tabular}\n');

    fprintf(outputFile, '\\vspace{0.5cm}\n');

    fprintf(outputFile, '\\caption{\\webkbTableCaption}\n');
    fprintf(outputFile, '\\label{tab:table_webkb_PRBEP}\n' );
    fprintf(outputFile, '\\end{table}\n');

    fclose(outputFile);
end
    
%% printWebKBLine

function printWebKBLine(~, outputFile, firstColumn, className, numeriaclValues)
    [~, maxPosition] = max(numeriaclValues);
    stringValues = cellstr(num2str(numeriaclValues, '%.1f'));
    stringValues{maxPosition} = ['\textbf{' stringValues{maxPosition} '}'];
    fprintf(outputFile, lineFormat, firstColumn, className, ...
            stringValues{SmallWebKBTable.MAD},stringValues{SmallWebKBTable.AM}, stringValues{SmallWebKBTable.CSSL});
end

end % static methods

end % classdef