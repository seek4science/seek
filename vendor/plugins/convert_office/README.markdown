ConvertOffice
=============

It is a ruby Wrapper of [jodconverter][1] Which is used to convert office format to another office format/html 
[1]: http://www.artofsolving.com/opensource/jodconverter.

Install
-------

<code>./script/plugin install git://github.com/amardaxini/convert_office.git</code>
 
Requirements
------------

JDK 1.5.x or 1.6.x

OpenOffice 2,3 or greater

Start Office with headless mode.
 
<code>
  soffice -headless -accept="socket,host=127.0.0.1,port=8100;urp;" -nofirststartwizard
</code>
Configuration
-------------

These are the default settings which can be overwritten in your enviroment configuration file.
<code>
    ConvertOffice::ConvertOfficeConfig.options = {
      :java_bin => "java",          # java binary
      :nailgun =>false,             # for nailgun support
      :soffice_port=>8100           # Open office port no
    }
</code>
Example
=======
If destination file is known.destination file consist valid file format

<code>
  ConvertOffice::ConvertOfficeFormat.new.convert(src_file,dest_file)
</code>

If format is known then
 
<code>
  ConvertOffice::ConvertOfficeFormat.new.convert(src_file,"",format)
</code>


Valid Format
============

To see valid format for conversion.

<code>
  ConvertOffice::ConvertOfficeFormat.display_valid_format(input file name/format optional field)
</code>

Advance Configuraion
====================
To speed up conversion process using nailgun server,do following steps

<code>
 ./script/plugin install git://github.com/amardaxini/nailgun.git
</code>

Start nailgun server.Before starting nailgun server make sure that your **classpath environment variable** set and point to jre/lib

<code>
  rake nailgun
</code>

<code>
 script/nailgun start
</code>

you have to overwrite Configuration make **nailgun option to true**
Now after making nailgun option true run

<code>
  rake convert_office
</code>

<code>
  script/convet_office_nailgun
</code>

Copyright (c) 2010 [amardaxini][1], released under the MIT license
[1]: http://railstech.com
