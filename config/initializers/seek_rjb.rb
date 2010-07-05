#RJB
if SPREADSHEET_PARSING_ENABLED
  ENV['JAVA_HOME'] = "/usr/lib/jvm/java-1.5.0-sun" unless defined? JAVA_HOME
  
  require 'rjb'
  Rjb::load("./lib/poi.jar:"+
            "./lib/poi-ooxml.jar:"+
            "./lib/ooxml-lib/xmlbeans-2.3.0.jar:"+
            "./lib/ooxml-lib/geronimo-stax-api_1.0_spec-1.0.jar:"+
            "./lib/ooxml-lib/dom4j-1.6.1.jar:"+
            "./lib/poi-ooxml-schemas-3.6-20091214.jar:")
  
  CELL_CLASS = Rjb::import('org.apache.poi.ss.usermodel.Cell')
  DATEUTIL_CLASS = Rjb::import('org.apache.poi.ss.usermodel.DateUtil')
  
  XLS_WORKBOOK_CLASS = Rjb::import('org.apache.poi.hssf.usermodel.HSSFWorkbook')
  XLSX_WORKBOOK_CLASS = Rjb::import('org.apache.poi.xssf.usermodel.XSSFWorkbook')
  
  STREAM_CLASS = Rjb::import('java.io.BufferedInputStream')
  URI_CLASS = Rjb::import('java.net.URI')
end