/**
* @author 		Ramón Prades
* @date 		October 2025
* @group 		Leads
* @description 	Imports files from MB anbd creates the corresponding leads
*/   
public class BatchMaterialBankImporter implements Queueable, Database.AllowsCallouts {

    private static final String NAMESPACE = 'MATERIAL-BANK';

    private static final String SOURCE_FOLDER = '/inbox/';
    private static final String PROCESSED_FOLDER = '/processed/';
    private static final String STORAGE_NAME = 'mbank';        

    private MBFileDTO[] filesToProcess;
    String[] filesToMove;
    private SYS_BatchJournal batchJournal;
    private SystemLog logger;
    private Boolean isFirstExecution = true;

    public static void executeNow() {
        BatchMaterialBankImporter newImporter = new BatchMaterialBankImporter();
        System.enqueueJob(newImporter);
    }

    @future(callout=true)
    public static void moveFiles(String files) {
        String[] paths = files.split(',');
        StorageAPIHelper helper = new StorageAPIHelper(STORAGE_NAME);
        for (String path : paths) {                      
            helper.moveFile(path, PROCESSED_FOLDER);
        }
    }

    public BatchMaterialBankImporter() {
        this.isFirstExecution = true;
        this.batchJournal = new SYS_BatchJournal(this);        
        this.batchJournal.start();
        this.logger = new SystemLog('REST-STREAM');
        this.logger.addInfo('Se lanza la ejecución de la import de Material Bank con la clase BatchMaterialBankImporter');
        this.logger.addInfo('Se han leído ' + (this.filesToProcess?.size() ?? 0) + ' ficheros del FTP');
    }

    public BatchMaterialBankImporter(MBFileDTO[] files, SystemLog logger, SYS_BatchJournal journal) {
        this.isFirstExecution = false;
        this.filesToProcess = files;
        this.logger = logger;
        this.batchJournal = journal;
    }

    public void execute(QueueableContext context) {
        if (this.isFirstExecution) {
            this.readFiles();
        }
        Integer index = 0;
        MBFileDTO currentFile = null;
        for (MBFileDTO file : this.filesToProcess) {
            index++;  
            if (file.Processed) {
                continue;
            }
            SYS_ProcessReceipt receipt = new SYS_ProcessReceipt(NAMESPACE, file.fileName);
            if (receipt.exists()) {
                this.logger.addSection('Saltando fichero número ' + index + ' (ya ha sido procesado en alguna ejecución anterior)');
                file.Processed = true;
                continue;
            }
            // New file : Process it.
            currentFile = file;
            break;
        }
        if (currentFile != null) {
            SYS_ProcessReceipt receipt = new SYS_ProcessReceipt(NAMESPACE, currentFile.fileName);
            String parserType = this.getParserType(currentFile.FileName);
            this.logger.addSection('Procesando fichero número ' + index);
            this.logger.addInfo('==> Nombre: ' + currentFile.FileName);
            this.logger.addInfo('==> Path: ' + currentFile.Path);
            this.logger.addInfo('==> Parser: ' + parserType);
            this.logger.addInfo('==> Content Length: ' + currentFile.Content?.length());
            try {
                Type instanceType = Type.forName(parserType);
                AbstractStreamParser parser = (AbstractStreamParser) instanceType.newInstance();
                parser.content = currentFile.Content;
                parser.fileName = currentFile.FileName;
                if (String.isNotBlank(currentFile.Content)) {
                    parser.parse();
                    String jsonResult = parser.execute();
                    this.logger.addInfo('==> Fichero processed succesfully: ' + jsonResult);                    
                } else {
                    this.logger.addInfo('==> Fichero ignorado por longitud 0');
                }
                currentFile.Processed = true;            
                receipt.save(true, 'Material Bank File processed');
            } catch (Exception ex) {
                this.logger.addError(ex);
            }
            BatchMaterialBankImporter newImporter = new BatchMaterialBankImporter(this.filesToProcess, this.logger, this.batchJournal);
            if (Test.isRunningTest()) {
                this.finish();          // Para evitar límites
            } else {
                System.enqueueJob(newImporter);
            }
        } else {
            this.finish();
        }
    }

    public void finish() {
        this.logger.addSection('CIERRE DEL JOB');
        try {
            BatchMaterialBankImporter.moveFiles(this.processedFilesString());        
        } catch(Exception ex) {
            this.logger.addError(ex);
        }
        this.logger.saveLog(true);        
        this.batchJournal.end(this.logger.hasErrors(), 'Job executed with ' + ((this.logger.hasErrors()) ? ' errors' : ' success'));
    }
    
    private String processedFilesString() {
        List<String> processed = new List<String>();
        for (MBFileDTO dto: this.filesToProcess) {
            if (dto.Processed) {
                processed.add(dto.Path);
            }
        }
        return String.join(processed, ',');
    }

    private void readFiles() {
        this.filesToProcess = new List<MBFileDTO> ();
        StorageAPIHelper helper = new StorageAPIHelper(STORAGE_NAME);
        StorageAPIHelper.DirectoryDTO directory = helper.dir(SOURCE_FOLDER);
        for (StorageAPIHelper.DirectoryEntryDTO entry : directory.items) {
            MBFileDTO dto = new MBFileDTO();
            dto.FileName = entry.Name;
            dto.Path = entry.Url;
            if (entry.Size > 0) {
                dto.Content = helper.readTextFile(dto.Path);
            }
            dto.Processed = false;
            this.filesToProcess.add(dto);
        }    
    }

    private String getParserType(String fileName) {
        if (fileName?.containsIgnoreCase('_EU_')) {
            return 'MaterialBankEUParser';
        } else {
            return 'MaterialBankParser';
        }
    }

    public class MBFileDTO {
        public String FileName;
        public String Content;
        public String Path;
        public Boolean Processed;
    }
}