require 'convert_office_config'
module ConvertOffice
  class ConvertOfficeFormat
    Async = RUBY_PLATFORM =~ /win32|mswin|mingw/ ? "" : " >> /dev/null 2>&1 &"
    JAR_PATH= File.expand_path(File.join(File.dirname(__FILE__),"java","jar","convert_office.jar"))
    TEXT_FORMAT = %w(pdf odt sxw rtf  doc txt html wiki docx)
    XL_FORMAT = %w(pdf ods sxc xls csv tsv html xlsx)
    PT_FORMAT = %w(pdf swf odp sxi ppt html pptx)
    ODG_FORMAT = %w(svg swf)
    VALID_FORMAT=	{
      "odt"=>TEXT_FORMAT,
      "sxw"=>TEXT_FORMAT,
      "rtf"=>TEXT_FORMAT,
      "doc"=>TEXT_FORMAT,
      "docx"=>TEXT_FORMAT,
      "wpd"=>TEXT_FORMAT,
      "txt"=>TEXT_FORMAT,
      "html"=>TEXT_FORMAT,
      "htm"=>TEXT_FORMAT,
      "ods"=>XL_FORMAT,
      "sxc"=>XL_FORMAT,
      "xls"=>XL_FORMAT,
      "xlsx"=>XL_FORMAT,
      "csv"=>XL_FORMAT,
      "tsv"=>XL_FORMAT,
      "odp"=>PT_FORMAT,
      "sxi"=>PT_FORMAT,
      "ppt"=>PT_FORMAT,
      "pptx"=>PT_FORMAT,
      "odg"=>ODG_FORMAT
    }

    def convert(input_file,output_file="",format="")
      java_bin = ConvertOffice::ConvertOfficeConfig.options[:java_bin]
      port_no = ConvertOffice::ConvertOfficeConfig.options[:soffice_port]
      nailgun = ConvertOffice::ConvertOfficeConfig.options[:nailgun]
      input_extension_name = File.extname(input_file).split(".").last
      if format.blank? && output_file.blank?
        raise ArgumentError=>"Please provide format or output file"
      elsif output_file.blank?
        if check_valid_conversion?(input_extension_name,format)
          if nailgun
            command = "#{Nailgun::NgCommand::NGPATH} con -p #{port_no} -f #{format} #{input_file}"
          else
            command = "#{java_bin} -Xmx512m -Djava.awt.headless=true -cp #{JAR_PATH} com.artofsolving.jodconverter.cli.ConvertDocument -p #{port_no} -f #{format} #{input_file}"
          end
          system(command + Async)
        end
      elsif format.blank?
        output_format = File.extname(output_file).split(".").last
        if check_valid_conversion?(input_extension_name,output_format)
          if nailgun
            command = "#{Nailgun::NgCommand::NGPATH} con -p #{port_no} #{input_file} #{output_file}"
          else
            command = "#{java_bin} -Xmx512m -Djava.awt.headless=true -cp #{JAR_PATH} com.artofsolving.jodconverter.cli.ConvertDocument -p #{port_no} #{input_file} #{output_file}"
          end
          system(command + Async)
        end
      end
    end

    def self.display_valid_format(file_name="")
      if !file_name.blank?
        input_extension_name = file_name.split(".").last
        if VALID_FORMAT[input_extension_name].nil?
          puts "Not A Proper Format"
          VALID_FORMAT.each do |k,v|
            puts "#{k} => #{v.join(",")}"
          end
        else
          puts VALID_FORMAT[input_extension_name].join(",")
        end
      else
        VALID_FORMAT.each do |k,v|
          puts "#{k} => #{v.join(",")}"
        end
      end
    end  
    
    def check_valid_conversion?(input_ext,format)
      if VALID_FORMAT[input_ext].nil?
        puts "Please provide proper input file"
        puts "Input file type #{VALID_FORMAT.keys.join(",")}"
        return false
      elsif	!VALID_FORMAT[input_ext].include?(format)
        puts "Please provide proper output format/output file"
        puts "Format/Output file must be #{VALID_FORMAT[input_ext].join(",")}"
        return false
      else
        return true
      end
    end
  end
end
