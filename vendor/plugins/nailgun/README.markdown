Nailgun
=======
  [Nailgun][1] is server that preloads JVM so no need to load JVM on each request.


   nailgun is a ruby wrapper of nailgun server and it's command.


  Make sure before installing You have to set **classpath environment variable**
  which is point to jre/lib path.


  [1]:http://martiansoftware.com/nailgun
Install
=======

<code>./script/plugin install git://github.com/amardaxini/nailgun.git</code>

<code>rake nailgun</code>

OR
<code> sudo gem install nailgun </code>



Configuration
==============

These are the default settings which can be overwritten in your enviroment configuration file:
<code>


    Nailgun::NailgunConfig.options =
      {
          :java_bin => "java",
           :server_address =>'localhost',
          :port_no=>'2113'
      }


</code>
Example
=======
Run Rake Task

Install as a plugin

<code>
  rake nailgun
</code>


It will generate nailgun_config binary.

To start nailgun server(if you want you can overwrite default configuration)

<code> nailgun_config start</code>

To stop nailgun server

<code>nailgun_config stop</code>

Install as a Gem
It will generate local configuration for nailgun_config
update nailgun configuration and manage nailgun

To start nailgun server(if you want you can overwrite default configuration)

<code> nailgun_config start</code>

To stop nailgun server

<code>nailgun_config stop</code>

To add client side jar

<code>Nailgun::NgCommand.ng_cp(absolute jar path)</code>

To create alias of class

<code>Nailgun::NgCommand.ng_alias(alias name,class name)</code>

Make sure that class name is exist in client side jar path and its contain main
To easy to use nailgun server best way is combine all jar to make one jar

Copyright (c) 2010 [amardaxini][1], released under the MIT license
[1]: http://railstech.com
